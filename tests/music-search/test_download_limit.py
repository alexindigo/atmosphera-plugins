"""Offline public-helper regression tests. Run only inside the project VM."""

import concurrent.futures
import functools
import http.server
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]


class DownloadLimit(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory()
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name)
        self.music = self.root / "Music with spaces"
        self.music.mkdir()
        self.state = self.root / "state"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.env = dict(os.environ, MUSIC_CACHE_DIR=str(self.state),
                        PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
                        STUB_LOG=str(self.root / "calls"), STUB_SIZE="1048576")
        stub = self.bin / "yt-dlp"
        stub.write_text('''#!/usr/bin/env python3
import os, pathlib, sys, time
args = sys.argv[1:]
with open(os.environ["STUB_LOG"], "a") as log:
    log.write("download\\n")
time.sleep(float(os.environ.get("STUB_DELAY", "0")))
template = args[args.index("-o") + 1]
name = template.replace("%(title)s", "Fixture").replace("%(id)s", "id").replace("%(ext)s", "mp3")
with open(name, "wb") as output:
    output.truncate(int(os.environ["STUB_SIZE"]))
if os.environ.get("STUB_FAIL"):
    sys.exit(1)
''')
        stub.chmod(0o755)
        self.command("set-download-dir", str(self.music))

    def command(self, *args, expected=0):
        result = subprocess.run(["bash", str(ROOT / "music-search/musicctl.sh"), *args],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stderr)
        return result

    def download(self, expected=0):
        return self.command("download-mp3", "Fixture", "https://example.invalid/track", expected=expected)

    def records(self):
        return json.loads((self.state / "downloads.json").read_text())["files"]

    def playback(self, action, *args, expected=0):
        result = subprocess.run(["python3", str(ROOT / "music-search/lib/playback-cache.py"),
                                 action, str(self.state), *args],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stderr)
        return result

    def prepare_playback(self):
        return Path(self.playback("prepare", "https://example.invalid/track", "").stdout.strip())

    def playback_records(self):
        return json.loads((self.state / "playback.json").read_text())["files"]

    def test_apply_keeps_all_user_files_and_does_not_count_them(self):
        foreign = self.music / "user.txt"
        foreign.write_bytes(b"user" * 524288)
        nested = self.music / "album"
        nested.mkdir()
        (nested / "song.mp3").write_bytes(b"keep")
        self.command("set-cache-size", "1")
        self.assertEqual(foreign.stat().st_size, 2097152)
        self.download()
        self.assertEqual((nested / "song.mp3").read_bytes(), b"keep")
        self.assertTrue(foreign.exists())

    def test_at_limit_refuses_before_producer_and_manual_delete_frees_space(self):
        self.command("set-cache-size", "1")
        first = Path(self.download().stdout.strip())
        result = self.download(expected=3)
        self.assertIn("Download limit reached", result.stderr)
        self.assertIn("keeps your files", result.stderr)
        self.assertEqual((self.root / "calls").read_text().count("download"), 1)
        self.assertEqual(first.stat().st_size, 1048576)
        first.unlink()  # Simulate the user's independent deletion, not plugin code.
        self.download()
        self.assertEqual(len(self.records()), 1)

    def test_over_limit_preserved_and_zero_is_unlimited(self):
        first = Path(self.download().stdout.strip())
        second = Path(self.download().stdout.strip())
        self.assertNotEqual(first, second)
        self.command("set-cache-size", "1")
        self.download(expected=3)
        self.assertTrue(first.exists() and second.exists())
        self.command("set-cache-size", "0")
        self.download()

    def test_admitted_download_can_cross_limit(self):
        self.command("set-cache-size", "1")
        self.env["STUB_SIZE"] = "2097152"
        first = Path(self.download().stdout.strip())
        self.download(expected=3)
        self.assertEqual(first.stat().st_size, 2097152)

    def test_existing_collision_and_symlink_are_never_overwritten_or_adopted(self):
        foreign = self.music / "Fixture [id].mp3"
        foreign.write_text("user music")
        link = self.music / "Fixture [id] (1).mp3"
        link.symlink_to(foreign)
        output = Path(self.download().stdout.strip())
        self.assertEqual(foreign.read_text(), "user music")
        self.assertTrue(link.is_symlink())
        self.assertEqual(output.name, "Fixture [id] (2).mp3")
        self.assertEqual([entry["path"] for entry in self.records()], [str(output)])

    def test_changed_folder_has_independent_budget(self):
        self.command("set-cache-size", "1")
        old = Path(self.download().stdout.strip())
        self.command("set-download-dir", str(self.root / "other"))
        self.download()
        self.assertTrue(old.exists())
        self.command("set-download-dir", str(self.music))
        self.download(expected=3)

    def test_concurrent_admission_is_serialized(self):
        self.command("set-cache-size", "1")
        self.env["STUB_DELAY"] = "0.2"
        def attempt():
            return subprocess.run(["bash", str(ROOT / "music-search/musicctl.sh"),
                                   "download-mp3", "Fixture", "https://example.invalid/track"],
                                  env=self.env, capture_output=True).returncode
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
            self.assertEqual(sorted(pool.map(lambda _: attempt(), range(2))), [0, 3])
        self.assertEqual(len(self.records()), 1)

    def test_corrupt_record_fails_closed_without_touching_music(self):
        output = Path(self.download().stdout.strip())
        (self.state / "downloads.json").write_text("corrupt")
        self.download(expected=1)
        self.assertEqual(output.stat().st_size, 1048576)

    def test_stop_keeps_media_even_when_download_and_runtime_folders_overlap(self):
        self.command("set-download-dir", str(self.state))
        source = self.state / "current-media.mp3"
        source.write_bytes(b"saved music")
        self.command("stop")
        self.assertEqual(source.read_bytes(), b"saved music")

    def test_cached_playback_keeps_existing_media_without_growing_private_cache(self):
        mpv = self.bin / "mpv"
        mpv.write_text('#!/bin/sh\nexit 0\n')
        mpv.chmod(0o755)
        original = self.state / "current-media.mp3"
        original.write_bytes(b"saved music")
        command = ('source "$1/lib/config.sh"; source "$1/lib/launch.sh"; '
                   'launch_youtube_cached https://example.invalid/track; wait')
        for _ in range(2):
            subprocess.run(["bash", "-c", command, "_", str(ROOT / "music-search")],
                           check=True, env=self.env)
        self.assertEqual(original.read_bytes(), b"saved music")
        outputs = list(self.state.glob("playback.*/*"))
        self.assertEqual(len(outputs), 1)
        self.assertTrue(all(path.stat().st_size == 1048576 for path in outputs))
        self.command("stop")
        self.assertEqual(list(self.state.glob("playback.*")), [self.state / "playback.json"])
        self.assertEqual(original.read_bytes(), b"saved music")

    def test_download_claim_permanently_prevents_playback_deletion(self):
        source = self.prepare_playback()
        record = self.playback_records()[0]
        (self.state / "downloads.json").write_text(json.dumps({"version": 1, "files": [record]}))
        self.command("set-download-dir", str(self.state))
        self.command("stop")
        self.assertTrue(source.exists())
        self.assertEqual(self.playback_records(), [])
        # Relinquishing playback ownership survives loss of download bookkeeping.
        (self.state / "downloads.json").write_text('{"version":1,"files":[]}')
        self.command("stop")
        self.assertTrue(source.exists())

    def test_cleanup_preserves_download_in_overlapping_private_directory(self):
        source = self.prepare_playback()
        self.command("set-download-dir", str(source.parent))
        saved = Path(self.download().stdout.strip())
        self.command("stop")
        self.assertFalse(source.exists())
        self.assertEqual(saved.stat().st_size, 1048576)
        self.prepare_playback()
        self.command("stop")
        self.assertEqual(saved.stat().st_size, 1048576)

    def test_replaced_playback_file_and_unrecorded_sibling_are_not_deleted(self):
        source = self.prepare_playback()
        foreign = source.parent / "foreign.mp3"
        foreign.write_bytes(b"user music")
        os.replace(foreign, source)
        foreign.write_bytes(b"more user music")
        self.command("stop")
        self.assertEqual(source.read_bytes(), b"user music")
        self.assertEqual(foreign.read_bytes(), b"more user music")

    def test_interrupted_quarantine_is_recovered_by_exact_record(self):
        source = self.prepare_playback()
        record = self.playback_records()[0]
        directory = source.parent / ".cleanup-fixture"
        directory.mkdir(mode=0o700)
        info = directory.stat()
        record.update(quarantine=str(directory / "media"),
                      quarantine_device=info.st_dev, quarantine_inode=info.st_ino)
        (self.state / "playback.json").write_text(json.dumps({"version": 1, "files": [record]}))
        source.rename(directory / "media")
        self.command("stop")
        self.assertFalse(source.parent.exists())
        self.assertEqual(self.playback_records(), [])

    def test_replacement_during_capture_is_restored_not_deleted(self):
        source = self.prepare_playback()
        spec = importlib.util.spec_from_file_location("playback_cache", ROOT / "music-search/lib/playback-cache.py")
        module = importlib.util.module_from_spec(spec)
        sys.path.insert(0, str(ROOT / "music-search/lib"))
        try:
            spec.loader.exec_module(module)
        finally:
            sys.path.pop(0)
        rename = module.rename_noreplace
        calls = 0
        def swap_before_capture(*args):
            nonlocal calls
            calls += 1
            if calls == 1:
                source.rename(source.parent / "original")
                source.write_bytes(b"user replacement")
            return rename(*args)
        with mock.patch.object(module, "rename_noreplace", side_effect=swap_before_capture):
            module.cleanup(self.state)
        self.assertEqual(source.read_bytes(), b"user replacement")
        self.assertTrue((source.parent / "original").exists())

    def test_corrupt_download_record_blocks_playback_cleanup(self):
        source = self.prepare_playback()
        (self.state / "downloads.json").write_text("corrupt")
        self.playback("cleanup", expected=1)
        self.assertEqual(source.stat().st_size, 1048576)

    def test_failed_producer_is_owned_and_removed_on_cleanup(self):
        self.env["STUB_FAIL"] = "1"
        self.playback("prepare", "https://example.invalid/track", "", expected=1)
        source = Path(self.playback_records()[0]["path"])
        self.assertTrue(source.exists())
        self.command("stop")
        self.assertFalse(source.exists())

    @unittest.skipUnless(shutil.which("yt-dlp"), "real yt-dlp not installed")
    def test_real_downloader_with_loopback_fixture_preserves_owned_inode(self):
        real = shutil.which("yt-dlp")
        (self.bin / "yt-dlp").write_text('#!/bin/sh\nexec "' + real + '" "$@"\n')
        original = self.root / "fixture.mp3"
        subprocess.run(["ffmpeg", "-v", "error", "-f", "lavfi", "-i", "sine=duration=0.1",
                        str(original)], check=True, env=self.env)
        class Handler(http.server.SimpleHTTPRequestHandler):
            def log_message(self, *args):
                pass
        server = http.server.ThreadingHTTPServer(("127.0.0.1", 0),
                    functools.partial(Handler, directory=str(self.root)))
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            url = f"http://127.0.0.1:{server.server_port}/fixture.mp3"
            source = Path(self.playback("prepare", url, "").stdout.strip())
            self.assertEqual(source.read_bytes(), original.read_bytes())
            self.assertEqual(source.stat().st_ino, self.playback_records()[0]["inode"])
            self.command("stop")
            self.assertFalse(source.exists())
        finally:
            server.shutdown()
            server.server_close()
            thread.join()

    def test_local_conversion_preserves_input_and_collision(self):
        source = self.music / "Local.mp3"
        subprocess.run(["ffmpeg", "-v", "error", "-f", "lavfi", "-i", "sine=duration=0.1",
                        str(source)], check=True, env=self.env)
        before = source.read_bytes()
        output = Path(self.command("download-mp3", "Local", str(source)).stdout.strip())
        self.assertEqual(source.read_bytes(), before)
        self.assertEqual(output.name, "Local (1).mp3")
        self.assertGreater(output.stat().st_size, 0)
        self.command("set-cache-size", "1")
        with output.open("ab") as stream:
            stream.truncate(1048576)
        self.command("download-mp3", "Local", str(source), expected=3)
        self.assertEqual(source.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
