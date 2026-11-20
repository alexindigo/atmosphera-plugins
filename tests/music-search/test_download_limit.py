"""Offline public-helper regression tests. Run only inside the project VM."""

import concurrent.futures
import contextlib
import fcntl
import functools
import http.server
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import signal
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

    def download_module(self):
        spec = importlib.util.spec_from_file_location("download_review", ROOT / "music-search/lib/downloads.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_full_length_names_reserve_collision_suffix_bytes(self):
        module = self.download_module()
        capacity = os.pathconf(self.music, "PC_NAME_MAX")
        for stem in ("x" * (capacity - 4), "é" * ((capacity - 4) // 2)):
            with self.subTest(stem=stem[:1]):
                source = self.root / (stem + ".mp3")
                source.write_bytes(b"new")
                existing = self.music / source.name
                existing.write_bytes(b"user music")
                with mock.patch.object(module, "produce", return_value=source):
                    self.assertEqual(module.download(self.state, self.music, 0, "", "", ""), 0)
                output = Path(self.records()[-1]["path"])
                self.assertLessEqual(len(os.fsencode(output.name)), capacity)
                self.assertTrue(output.name.endswith(" (1).mp3"))
                self.assertEqual(output.read_bytes(), b"new")
                self.assertEqual(existing.read_bytes(), b"user music")

    def test_publication_records_descriptor_identity_even_after_replacement_or_failure(self):
        module = self.download_module()
        source = self.root / "Publication.mp3"
        source.write_bytes(b"new")
        copy = module.copy_complete
        for failure in (False, True):
            with self.subTest(failure=failure):
                created = []
                def replace_during_copy(incoming, target):
                    copy(incoming, target)
                    target.flush()
                    created.append(os.fstat(target.fileno()))
                    output = Path(target.name)
                    output.rename(output.with_suffix(".original"))
                    output.write_bytes(b"foreign replacement")
                    if failure:
                        raise OSError("fixture copy failed")
                with mock.patch.object(module, "produce", return_value=source), \
                     mock.patch.object(module, "copy_complete", side_effect=replace_during_copy):
                    if failure:
                        with self.assertRaises(OSError):
                            module.download(self.state, self.music, 0, "", "", "")
                    else:
                        module.download(self.state, self.music, 0, "", "", "")
                record = self.records()[-1]
                output = Path(record["path"])
                self.assertEqual((record["device"], record["inode"]),
                                 (created[0].st_dev, created[0].st_ino))
                self.assertNotEqual(output.stat().st_ino, record["inode"])
                self.assertEqual(output.read_bytes(), b"foreign replacement")
                self.assertNotIn(str(output), [r["path"] for r in module.live_records(self.state / "downloads.json")])

    def test_publication_completes_short_writes_and_accounts_for_write_failures(self):
        module = self.download_module()
        open_file = Path.open
        payload = b"complete audio bytes"
        for outcome in ("short", "zero", "error"):
            with self.subTest(outcome=outcome):
                source = self.root / (outcome + ".mp3")
                source.write_bytes(payload)

                class PartialWriter:
                    def __init__(self, target):
                        self.target = target
                        self.calls = 0

                    def __getattr__(self, name):
                        return getattr(self.target, name)

                    def __enter__(self):
                        return self

                    def __exit__(self, *args):
                        return self.target.__exit__(*args)

                    def write(self, data):
                        self.calls += 1
                        if self.calls > 1 and outcome == "zero":
                            return 0
                        if self.calls > 1 and outcome == "error":
                            raise OSError("fixture volume full")
                        return self.target.write(data[:2])

                def open_partial(path, mode="r", *args, **kwargs):
                    target = open_file(path, mode, *args, **kwargs)
                    return PartialWriter(target) if mode == "xb" else target

                reported = io.StringIO()
                with mock.patch.object(module, "produce", return_value=source), \
                     mock.patch.object(Path, "open", open_partial), \
                     contextlib.redirect_stdout(reported):
                    if outcome == "short":
                        self.assertEqual(module.download(self.state, self.music, 0, "", "", ""), 0)
                    else:
                        with self.assertRaises(OSError):
                            module.download(self.state, self.music, 0, "", "", "")
                output = self.music / source.name
                self.assertEqual(output.read_bytes(), payload if outcome == "short" else payload[:2])
                record = self.records()[-1]
                self.assertEqual(record["size"], output.stat().st_size)
                self.assertEqual(record["inode"], output.stat().st_ino)
                self.assertEqual(reported.getvalue().strip(), str(output) if outcome == "short" else "")

    def test_stop_defers_busy_cleanup_and_retries_without_blocking(self):
        source = self.prepare_playback()
        before = (self.state / "playback.json").read_bytes()
        with (self.state / "downloads.lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            process = subprocess.Popen(["bash", str(ROOT / "music-search/musicctl.sh"), "stop"],
                        env=self.env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                        text=True, start_new_session=True)
            try:
                stdout, stderr = process.communicate(timeout=1)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGTERM)
                process.communicate(timeout=2)
                self.fail("stop waited on the download production lock")
            self.assertEqual(process.returncode, 0, stderr)
            self.assertEqual(json.loads(stdout)["endReason"], "stopped")
            self.assertTrue(source.exists())
            self.assertEqual((self.state / "playback.json").read_bytes(), before)
        self.command("stop")
        self.assertFalse(source.exists())
        self.assertEqual(self.playback_records(), [])

    def test_stop_finalizes_endpoints_and_state_when_cleanup_fails(self):
        source = self.prepare_playback()
        before = (self.state / "playback.json").read_bytes()
        (self.state / "downloads.json").write_text("corrupt")
        for name in ("mpv.pid", "mpv.sock", "mpv.log"):
            (self.state / name).write_text("")
        result = self.command("stop")
        self.assertIn("cleanup", result.stderr.lower())
        self.assertEqual(json.loads(result.stdout)["endReason"], "stopped")
        self.assertFalse(json.loads((self.state / "state.json").read_text())["isPlaying"])
        self.assertTrue(source.exists())
        self.assertEqual((self.state / "playback.json").read_bytes(), before)
        self.assertEqual((self.state / "downloads.json").read_text(), "corrupt")
        self.assertTrue(all(not (self.state / name).exists() for name in ("mpv.pid", "mpv.sock", "mpv.log")))

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
