#!/usr/bin/env python3
"""Own exact fallback-source identities; saved-download ownership always wins."""

import ctypes
import errno
import fcntl
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile

from downloads import read_records, write_records


def same_file(info, entry):
    return stat.S_ISREG(info.st_mode) and (info.st_dev, info.st_ino) == (entry["device"], entry["inode"])


def remove_empty_directory(path, device, inode):
    try:
        info = path.lstat()
        if stat.S_ISDIR(info.st_mode) and (info.st_dev, info.st_ino) == (device, inode):
            path.rmdir()
    except OSError as error:
        if error.errno not in (errno.ENOENT, errno.ENOTEMPTY, errno.EEXIST):
            raise


def rename_noreplace(source, target, source_fd, target_fd):
    # Capture a path before checking its identity, never stat-then-unlink a
    # user-addressable name. A raced replacement is restored, not deleted.
    libc = ctypes.CDLL(None, use_errno=True)
    rename = libc.renameat2
    rename.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint]
    rename.restype = ctypes.c_int
    if rename(source_fd, os.fsencode(source), target_fd, os.fsencode(target), 1) != 0:
        number = ctypes.get_errno()
        raise OSError(number, os.strerror(number), source)


def remove_owned(cache, records, entry):
    path = Path(entry["path"])
    parent = path.parent
    try:
        parent_fd = os.open(parent, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    except FileNotFoundError:
        return
    try:
        info = os.fstat(parent_fd)
        if (info.st_dev, info.st_ino) != (entry["parent_device"], entry["parent_inode"]):
            return
        quarantine = entry.get("quarantine")
        if not quarantine:
            try:
                info = os.stat(path.name, dir_fd=parent_fd, follow_symlinks=False)
            except FileNotFoundError:
                return
            if not same_file(info, entry):
                return
            directory = Path(tempfile.mkdtemp(prefix=".cleanup-", dir=parent))
            info = directory.stat()
            entry.update(quarantine=str(directory / "media"),
                         quarantine_device=info.st_dev, quarantine_inode=info.st_ino)
            # A later cleanup can recover an interrupted capture without scanning.
            write_records(cache / "playback.json", records)
        directory = Path(entry["quarantine"]).parent
        try:
            quarantine_fd = os.open(directory, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        except FileNotFoundError:
            # Capture/delete already completed before an interrupted ledger write.
            try:
                os.stat(path.name, dir_fd=parent_fd, follow_symlinks=False)
            except FileNotFoundError:
                return
            raise ValueError("Playback cleanup state changed; files preserved.")
        try:
            info = os.fstat(quarantine_fd)
            if (info.st_dev, info.st_ino) != (entry["quarantine_device"], entry["quarantine_inode"]):
                raise ValueError("Playback cleanup directory replaced; files preserved.")
            try:
                captured = os.stat("media", dir_fd=quarantine_fd, follow_symlinks=False)
            except FileNotFoundError:
                try:
                    rename_noreplace(path.name, "media", parent_fd, quarantine_fd)
                except FileNotFoundError:
                    return
                captured = os.stat("media", dir_fd=quarantine_fd, follow_symlinks=False)
            if not same_file(captured, entry):
                rename_noreplace("media", path.name, quarantine_fd, parent_fd)
                return
            os.unlink("media", dir_fd=quarantine_fd)
        finally:
            os.close(quarantine_fd)
            remove_empty_directory(directory, entry["quarantine_device"], entry["quarantine_inode"])
    finally:
        os.close(parent_fd)
        remove_empty_directory(parent, entry["parent_device"], entry["parent_inode"])


def cleanup_locked(cache):
    records = read_records(cache / "playback.json")
    # Read even stale download claims: once handed to the download owner, a
    # path permanently loses playback-deletion authority. Corruption fails closed.
    protected = {entry["path"] for entry in read_records(cache / "downloads.json")}
    for entry in list(records):
        if entry["path"] not in protected and entry.get("quarantine") not in protected:
            remove_owned(cache, records, entry)
        records.remove(entry)
        write_records(cache / "playback.json", records)


def cleanup(cache):
    with (cache / "downloads.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            # Stopping a player must not wait for an unrelated MP3 producer.
            # Leave the ledger intact for the next stop or prepare transaction.
            return False
        cleanup_locked(cache)
        return True


def prepare(cache, url, extractor):
    with (cache / "downloads.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        cleanup_locked(cache)
        directory = Path(tempfile.mkdtemp(prefix="playback.", dir=cache))
        source = directory / "media"
        # Record the exact inode we created before giving the producer access.
        # No part/fixup/continuation allows it to write this file in place.
        with source.open("xb") as created:
            info = os.fstat(created.fileno())
        parent = directory.stat()
        entry = {"path": str(source), "device": info.st_dev, "inode": info.st_ino,
                 "parent_device": parent.st_dev, "parent_inode": parent.st_ino}
        write_records(cache / "playback.json", [entry])
        args = ["yt-dlp", "--ignore-config", "--no-warnings", "--no-part", "--no-playlist",
                "--no-continue", "--force-overwrites", "--fixup", "never", "-f", "bestaudio/best",
                "-o", str(source)]
        if extractor:
            args.append(extractor)
        with (cache / "mpv.log").open("ab") as log:
            subprocess.run(args + ["--", url], check=True, stdout=log, stderr=log)
        if not same_file(source.lstat(), entry):
            raise ValueError("Playback source replaced; file preserved.")
        return source


if __name__ == "__main__":
    try:
        action, cache = sys.argv[1], Path(sys.argv[2]).resolve()
        if action == "cleanup":
            if not cleanup(cache):
                print("Playback cleanup deferred until the next stop or cached play; download is busy.", file=sys.stderr)
                sys.exit(4)
        elif action == "prepare":
            print(prepare(cache, sys.argv[3], sys.argv[4]))
        elif action == "play":
            source = prepare(cache, sys.argv[3], sys.argv[4])
            os.execvp("mpv", ["mpv", "--no-video", "--force-window=no", "--audio-display=no",
                             "--demuxer-max-bytes=256K", "--speed=" + sys.argv[5],
                             "--log-file=" + str(cache / "mpv.log"),
                             "--input-ipc-server=" + str(cache / "mpv.sock"),
                             "--title=Noctalia music-search", str(source)])
        else:
            raise ValueError("Unknown playback cache action.")
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as error:
        print(f"Playback cache failed: {error}", file=sys.stderr)
        sys.exit(1)
