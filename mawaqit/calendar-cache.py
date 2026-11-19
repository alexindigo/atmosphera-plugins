#!/usr/bin/env python3
"""Plugin-owned calendar cache. No preference writes; all IO runs in this child."""
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import re
import sys
import tempfile
import time


class CacheError(Exception):
    pass


def decode(data):
    return json.loads(data, parse_constant=lambda _: (_ for _ in ()).throw(CacheError("json")))


def month_key(year, month):
    if type(year) is not int or type(month) is not int or not 1 <= year <= 9999 or not 1 <= month <= 12:
        raise CacheError("month")
    return f"{year}_{month}"


def valid_entry(entry):
    return (type(entry) is dict and type(entry.get("timestamp")) in (int, float)
            and math.isfinite(entry["timestamp"]) and entry["timestamp"] > 0
            and type(entry.get("data")) is list
            and all(type(day) is dict for day in entry["data"]))


def observe(path):
    """Capture bytes and file/target identities, including an absent observation."""
    try:
        link = path.lstat()
    except FileNotFoundError:
        return None, {"present": False}
    with path.open("rb") as stream:
        before = os.fstat(stream.fileno())
        data = stream.read()
        after = os.fstat(stream.fileno())
    identity = lambda st: [st.st_dev, st.st_ino, st.st_size, st.st_mtime_ns, st.st_ctime_ns]
    if identity(before) != identity(after) or identity(link) != identity(path.lstat()):
        raise CacheError("source-changed")
    if identity(after) != identity(path.stat()):
        raise CacheError("source-changed")
    return data, {"present": True, "link": identity(link), "target": identity(after),
                  "sha256": hashlib.sha256(data).hexdigest()}


def adoption(state, user, legacy):
    # A completed marker is in the same atomic document as every adopted entry.
    # Old preference keys are never opened again, even after invalidate/prune.
    if state.get("adoption") is not None:
        return None
    raw_user, user_revision = observe(user)
    selected = {} if raw_user is None else decode(raw_user)
    if type(selected) is not dict:
        raise CacheError("source-shape")
    revisions = {"user": user_revision}
    if not selected:
        raw_legacy, revisions["legacy"] = observe(legacy)
        selected = {} if raw_legacy is None else decode(raw_legacy)
        if type(selected) is not dict:
            raise CacheError("source-shape")
    ignored = 0
    for key, raw in selected.items():
        match = re.fullmatch(r"_cal_([0-9]{1,4})_([0-9]{1,2})", key)
        if not match:
            continue
        try:
            key = month_key(*map(int, match.groups()))
            entry = decode(raw) if type(raw) is str else None
            if not valid_entry(entry):
                raise CacheError("entry")
        except (ValueError, TypeError, CacheError):
            ignored += 1
            continue
        existing = state["entries"].get(key)
        if existing is None or existing["timestamp"] < entry["timestamp"]:
            state["entries"][key] = entry
    state["adoption"] = {"sources": revisions, "ignored": ignored}

    def confirm():
        if observe(user)[1] != user_revision:
            raise CacheError("source-changed")
        if "legacy" in revisions and observe(legacy)[1] != revisions["legacy"]:
            raise CacheError("source-changed")
    return confirm


def publish(path, state, confirm):
    body = (json.dumps(state, ensure_ascii=False, allow_nan=False, separators=(",", ":")) + "\n").encode()
    fd, name = tempfile.mkstemp(prefix=".calendar-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(body)
            stream.flush()
            os.fsync(stream.fileno())
        if confirm:
            confirm()
        os.replace(name, path)
        directory = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
        if path.read_bytes() != body:
            raise CacheError("readback")
    finally:
        if os.path.exists(name):
            os.unlink(name)


def execute(cache_root, plugin_key, user, legacy, request):
    # Registry generates either the local id or six SHA256 hex digits + ':' + id.
    # Restrict this helper to its own plugin, rather than accepting path segments.
    if not re.fullmatch(r"(?:[0-9a-f]{6}:)?mawaqit", plugin_key):
        raise CacheError("plugin-key")
    if not all(p.is_absolute() for p in (cache_root, user, legacy)):
        raise CacheError("path")
    directory = cache_root / "plugins" / plugin_key / "calendar"
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (directory / "calendar.lock").open("a+b") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise CacheError("busy")
        path = directory / "calendar.json"
        if path.exists():
            state = decode(path.read_bytes())
            if (type(state) is not dict or state.get("format") != 1
                    or type(state.get("entries")) is not dict
                    or any(not re.fullmatch(r"[0-9]{1,4}_[0-9]{1,2}", key)
                           or not valid_entry(entry) for key, entry in state["entries"].items())):
                raise CacheError("cache-shape")
        else:
            state = {"format": 1, "adoption": None, "entries": {}}
        previous = json.dumps(state, sort_keys=True)
        confirm = adoption(state, user, legacy)
        op = request["op"]
        now = time.time() * 1000
        entry = None
        if op in ("load", "save", "invalidate"):
            key = month_key(request["year"], request["month"])
            if op == "save":
                entry = {"timestamp": now, "data": request["data"]}
                if not valid_entry(entry):
                    raise CacheError("entry")
                state["entries"][key] = entry
            elif op == "invalidate":
                state["entries"].pop(key, None)
            else:
                candidate = state["entries"].get(key)
                if candidate and now - candidate["timestamp"] <= 2592000000:
                    entry = candidate
        elif op == "clear":
            state["entries"] = {}
        elif op == "prune":
            state["entries"] = {key: value for key, value in state["entries"].items()
                                if now - value["timestamp"] <= 31536000000}
        elif op != "adopt":
            raise CacheError("operation")
        if previous != json.dumps(state, sort_keys=True):
            publish(path, state, confirm)
        return {"status": "ready", "entry": entry}


def main():
    try:
        if len(sys.argv) != 5:
            raise CacheError("arguments")
        result = execute(Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3]), Path(sys.argv[4]), decode(sys.stdin.read()))
    except CacheError as error:
        result = {"status": "failed", "error": str(error)}
    except (OSError, ValueError, TypeError, KeyError):
        result = {"status": "failed", "error": "cache-io-or-input"}
    print(json.dumps(result, ensure_ascii=False, allow_nan=False))
    return 1 if result["status"] == "failed" else 0


if __name__ == "__main__":
    sys.exit(main())
