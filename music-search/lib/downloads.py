#!/usr/bin/env python3
"""Admit downloads by owned bytes, never evict or overwrite a saved file."""

import fcntl
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile


LIMIT_REACHED = 3


def write_records(path, records):
    # The lock covers admission, production, publication and atomic bookkeeping.
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as out:
        json.dump({"version": 1, "files": records}, out)
        out.flush()
        os.fsync(out.fileno())
    os.replace(out.name, path)


def read_records(path):
    if not path.exists():
        return []
    data = json.loads(path.read_text())
    if not isinstance(data, dict) or data.get("version") != 1 or not isinstance(data.get("files"), list):
        raise ValueError("Invalid download record; preserve it for manual recovery.")
    if any(not isinstance(entry, dict) or not isinstance(entry.get("path"), str) for entry in data["files"]):
        raise ValueError("Invalid download path record; preserve it for manual recovery.")
    return data["files"]


def live_records(path):
    records = []
    seen = set()
    for entry in read_records(path):
        name = entry["path"]
        if name in seen:
            continue
        seen.add(name)
        try:
            info = os.lstat(name)
        except FileNotFoundError:
            continue
        # A replacement or symlink is not a file this plugin created.
        if not stat.S_ISREG(info.st_mode) or (info.st_dev, info.st_ino) != (entry["device"], entry["inode"]):
            continue
        records.append(dict(entry, size=info.st_size))
    return records


def produce(stage, title, url, extractor):
    if Path(url).is_file():
        name = Path(title or Path(url).name).stem or "Track"
        output = stage / (name + ".mp3")
        subprocess.run(["ffmpeg", "-n", "-i", url, "-vn", "-codec:a", "libmp3lame",
                        "-q:a", "2", str(output)], check=True, stdout=subprocess.DEVNULL,
                       stderr=subprocess.PIPE)
    else:
        args = ["yt-dlp", "--ignore-config", "--no-warnings", "--no-part", "--no-playlist",
                "-x", "--audio-format", "mp3", "--audio-quality", "0"]
        youtube = "youtube.com" in url or "youtu.be" in url
        if youtube and extractor:
            args.append(extractor)
        template = "%(title)s [yt-%(id)s].%(ext)s" if youtube else "%(title)s [%(id)s].%(ext)s"
        subprocess.run(args + ["-o", str(stage / template), "--", url], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    outputs = list(stage.glob("*.mp3"))
    if len(outputs) != 1 or outputs[0].is_symlink():
        raise ValueError("Downloader did not produce one MP3 file.")
    return outputs[0]


def copy_complete(incoming, target):
    while chunk := incoming.read(64 * 1024):
        remaining = memoryview(chunk)
        while remaining:
            written = target.write(remaining)
            if written is None or written <= 0:
                raise OSError("MP3 output write made no progress.")
            remaining = remaining[written:]


def download(cache, destination, limit, title, url, extractor):
    ledger = cache / "downloads.json"
    with (cache / "downloads.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        records = live_records(ledger)
        write_records(ledger, records)
        destination = destination.resolve()
        # Count only tracked files in the selected destination, never scan it.
        total = sum(item["size"] for item in records if Path(item["path"]).parent == destination)
        if limit > 0 and total >= limit * 1024 * 1024:
            print("Download limit reached. Music Search keeps your files. Increase the limit "
                  "or remove a downloaded file yourself to download more.", file=sys.stderr)
            return LIMIT_REACHED
        destination.mkdir(parents=True, exist_ok=True)
        # Only disposable producer intermediates live here, never saved music.
        with tempfile.TemporaryDirectory(prefix="download-", dir=cache) as scratch:
            source = produce(Path(scratch), title, url, extractor)
            capacity = os.pathconf(destination, "PC_NAME_MAX")
            suffix = 0
            while True:
                ending = ".mp3" if suffix == 0 else f" ({suffix}).mp3"
                stem = source.stem
                if capacity > 0:
                    while stem and len(os.fsencode(stem + ending)) > capacity:
                        stem = stem[:-1]
                    if not stem:
                        raise ValueError("Destination filename capacity is too small.")
                name = stem + ending
                output = destination / name
                try:
                    target = output.open("xb", buffering=0)
                    break
                except FileExistsError:
                    suffix += 1
            # Exclusive creation also protects existing symlinks and local inputs.
            # Even on an I/O failure, keep and account for the partial output.
            with target:
                try:
                    with source.open("rb") as incoming:
                        copy_complete(incoming, target)
                        os.fsync(target.fileno())
                finally:
                    # The pathname may already refer to an unrelated replacement.
                    info = os.fstat(target.fileno())
                    records.append({"path": str(output), "size": info.st_size,
                                    "device": info.st_dev, "inode": info.st_ino})
                    write_records(ledger, records)
            print(output)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(download(Path(sys.argv[1]), Path(sys.argv[2]), int(sys.argv[3]), *sys.argv[4:7]))
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as error:
        print(f"MP3 download failed: {error}", file=sys.stderr)
        sys.exit(1)
