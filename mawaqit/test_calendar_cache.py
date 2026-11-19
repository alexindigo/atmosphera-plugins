"""Run with a disk-backed TMPDIR; tests use only private preference fixtures."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("calendar_cache", Path(__file__).with_name("calendar-cache.py"))
cache = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(cache)


class CalendarCacheTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.user = self.root / "user.json"
        self.legacy = self.root / "legacy.json"
        self.path = self.root / "plugins/abc123:mawaqit/calendar/calendar.json"
        self.entry = {"timestamp": time.time() * 1000, "data": [{"gregorian": {"day": "7"}}]}
        self.legacy.write_text(json.dumps({"_cal_1448_1": json.dumps(self.entry), "opaque": [False, 0]}))
        self.legacy.chmod(0o444)
        self.before = self.identity(self.legacy)

    def identity(self, path):
        st = path.stat()
        return path.read_bytes(), st.st_ino, st.st_mtime_ns, st.st_mode

    def run_cache(self, op="load", **options):
        return cache.execute(self.root, "abc123:mawaqit", self.user, self.legacy,
                             {"op": op, "year": 1448, "month": 1, **options})

    def test_adoption_and_independent_restart_ignore_legacy(self):
        self.assertEqual(self.run_cache()["entry"], self.entry)
        self.assertEqual(self.identity(self.legacy), self.before)
        self.assertFalse(self.user.exists())
        self.assertIsNotNone(json.loads(self.path.read_text())["adoption"])
        self.run_cache("save", data=[{"new": True}])
        # A completed adoption never reopens either old source, even unreadable JSON.
        self.legacy.chmod(0o644)
        self.legacy.write_text("invalid")
        self.user.write_text("invalid")
        p = subprocess.run([sys.executable, "-B", str(Path(cache.__file__)), str(self.root),
                            "abc123:mawaqit", str(self.user), str(self.legacy)],
                           input=json.dumps({"op": "load", "year": 1448, "month": 1}),
                           text=True, capture_output=True, timeout=10, check=True)
        self.assertEqual(json.loads(p.stdout)["entry"]["data"], [{"new": True}])

    def test_whole_object_fallback_and_unknown_key(self):
        self.user.write_text('{"opaque":0}')
        self.assertIsNone(self.run_cache()["entry"])
        self.assertEqual(self.user.read_text(), '{"opaque":0}')

    def test_empty_user_uses_legacy(self):
        self.user.write_text("{}")
        self.assertEqual(self.run_cache()["entry"], self.entry)
        self.assertEqual(self.user.read_text(), "{}")

    def test_user_cache_wins_without_legacy_merge(self):
        other = {**self.entry, "data": [{"user": True}]}
        self.user.write_text(json.dumps({"_cal_1448_1": json.dumps(other)}))
        before = self.identity(self.user)
        self.assertEqual(self.run_cache()["entry"], other)
        self.assertEqual(self.identity(self.user), before)

    def test_atomic_publish_failure_retry_and_newer_retention(self):
        self.path.parent.mkdir(parents=True)
        newer = {**self.entry, "timestamp": self.entry["timestamp"] + 1000, "data": [{"newer": True}]}
        self.path.write_text(json.dumps({"format": 1, "adoption": None, "entries": {"1448_1": newer}}))
        before = self.path.read_bytes()
        with patch.object(cache.os, "replace", side_effect=PermissionError):
            with self.assertRaises(PermissionError):
                self.run_cache()
        self.assertEqual(self.path.read_bytes(), before)
        self.assertIsNone(json.loads(before)["adoption"])
        self.assertEqual(list(self.path.parent.glob(".calendar-*")), [])
        self.assertEqual(self.run_cache()["entry"], newer)
        self.assertEqual(self.identity(self.legacy), self.before)

    def test_partial_write_failure_has_no_marker(self):
        real_fsync = cache.os.fsync
        with patch.object(cache.os, "fsync", side_effect=OSError):
            with self.assertRaises(OSError):
                self.run_cache()
        self.assertFalse(self.path.exists())
        self.assertEqual(list(self.path.parent.glob(".calendar-*")), [])
        self.assertEqual(self.run_cache()["entry"], self.entry)

    def test_changed_source_refuses_mixed_generation_and_retries(self):
        real_observe = cache.observe
        count = 0

        def changed(path):
            nonlocal count
            if path == self.user:
                count += 1
                if count == 2:
                    self.user.write_text('{"opaque":0}')
            return real_observe(path)

        with patch.object(cache, "observe", side_effect=changed):
            with self.assertRaisesRegex(cache.CacheError, "source-changed"):
                self.run_cache()
        self.assertFalse(self.path.exists())
        self.assertIsNone(self.run_cache()["entry"])
        self.assertEqual(self.identity(self.legacy), self.before)

    def test_malformed_source_is_retained_and_retryable(self):
        self.user.write_text("broken")
        with self.assertRaises(ValueError):
            self.run_cache()
        self.assertFalse(self.path.exists())
        self.assertEqual(self.user.read_text(), "broken")
        self.user.write_text("{}")
        self.assertEqual(self.run_cache()["entry"], self.entry)

    def test_invalid_entries_never_become_cache_values(self):
        self.user.write_text(json.dumps({"_cal_1448_1": "not JSON", "_cal_1448_13": json.dumps(self.entry)}))
        self.assertIsNone(self.run_cache()["entry"])
        state = json.loads(self.path.read_text())
        self.assertEqual(state["adoption"]["ignored"], 2)
        self.assertEqual(state["entries"], {})

    def test_invalidate_clear_and_prune_never_resurrect(self):
        self.run_cache()
        self.run_cache("invalidate")
        self.assertIsNone(self.run_cache()["entry"])
        self.run_cache("save", data=[{"new": True}])
        self.run_cache("clear")
        self.assertIsNone(self.run_cache()["entry"])
        state = json.loads(self.path.read_text())
        state["entries"]["1448_1"] = {**self.entry, "timestamp": 1}
        self.path.write_text(json.dumps(state))
        self.assertIsNone(self.run_cache()["entry"])
        self.run_cache("prune")
        self.assertEqual(json.loads(self.path.read_text())["entries"], {})
        self.assertEqual(self.identity(self.legacy), self.before)
        self.assertFalse(self.user.exists())

    def test_foreign_cache_not_overwritten(self):
        self.path.parent.mkdir(parents=True)
        self.path.write_text("broken")
        with self.assertRaises(ValueError):
            self.run_cache()
        self.assertEqual(self.path.read_text(), "broken")

    def test_opaque_plugin_key_validation_and_checked_month(self):
        for key in ("../mawaqit", "abc:mawaqit", "abc123:other"):
            with self.assertRaisesRegex(cache.CacheError, "plugin-key"):
                cache.execute(self.root, key, self.user, self.legacy, {"op": "adopt"})
        for month in (0, 13, "1", True):
            with self.assertRaisesRegex(cache.CacheError, "month"):
                self.run_cache(month=month)
        self.assertFalse(self.path.exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
