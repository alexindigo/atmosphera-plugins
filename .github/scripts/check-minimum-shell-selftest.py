#!/usr/bin/env python3
"""Exercise the release resolver and QML scanner with isolated Git trees."""

import contextlib
import importlib
import io
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


checker = importlib.import_module("check-minimum-shell")
sys.path.insert(0, str(Path(sys.argv.pop(1)).resolve() / "Scripts/dev"))
lexer = importlib.import_module("qml-identifiers")


class FloorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        scratch = tempfile.TemporaryDirectory()
        cls.addClassCleanup(scratch.cleanup)
        root = Path(scratch.name)
        cls.shell = root / "shell"
        cls.shell.mkdir()
        cls.source = root / "Main.qml"

        def put(name, content):
            path = cls.shell / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)

        def snapshot():
            cls.git("add", ".")
            return cls.git("write-tree")

        cls.git("init", "-q")
        put("VERSION", "0.10.0\n")
        put("Services/Cache.qml", "pragma Singleton\nQtObject { property int old: 1 }\n")
        put("Widgets/Existing.qml", "Item {}\n")
        old = snapshot()
        cls.git("update-ref", "refs/tags/v0.10.0", old)
        cls.git("update-ref", "refs/tags/v5.0.0", old)  # inherited upstream
        put("Widgets/NImage.qml", "Item {}\n")
        put("NewModule/Added.qml", "Item {}\n")
        put("Services/Cache.qml", "pragma Singleton\nQtObject {\n"
            "  function newApi() {}\n  QtObject { function privateApi() {} }\n}\n")
        cls.pin = checker.Tree(cls.shell, snapshot(), lexer)
        put("VERSION", "0.11.0\n")
        cls.release = snapshot()

    @classmethod
    def git(cls, *args):
        return subprocess.check_output(["git", "-C", cls.shell, *args], text=True).strip()

    def target(self, floor):
        tags = self.git("tag", "--list").splitlines()
        newest = checker.latest_release(self.shell, tags)
        log = io.StringIO()
        with contextlib.redirect_stderr(log):
            tree = checker.resolve_target(self.shell, tags, newest, self.pin, floor)
        return tree, log.getvalue()

    def findings(self, code, target):
        self.source.write_text(code)
        return set(checker.source_findings(self.source, target, self.pin, lexer))

    def test_historical_tag_detects_types_modules_and_members(self):
        target, _ = self.target("0.10.0")
        self.assertEqual(self.findings("import qs.Services\nimport qs.Widgets\nimport qs.NewModule\n"
                         "NImage { property var handle: Cache.newApi() }\n", target), {
            "missing module qs.NewModule", "missing shell type qs.Widgets.NImage",
            "missing shell API qs.Services.Cache.newApi",
        })

    def test_alias_and_non_code(self):
        target, _ = self.target("0.10.0")
        self.assertEqual(self.findings("import qs.Services as S // aliased\n"
                         "// import qs.NewModule\nItem {\n"
                         " property string a: `text\nimport qs.NewModule\nS.Cache.newApi()`\n"
                         " property string b: \"S.Cache.newApi()\"\n"
                         " property var c: S.Cache.privateApi()\n}\n", target), set())
        self.assertEqual(self.findings("import qs.Services as S\nItem {\n"
                         " property var a: S /* comment */ . Cache . newApi()\n}\n", target), {
            "missing shell API qs.Services.Cache.newApi",
        })

    def test_missing_historical_tag_fails_closed(self):
        with self.assertRaisesRegex(ValueError, r"required historical tag v0\.9\.0 is missing"):
            self.target("0.9.0")

    def test_unpublished_fallback_then_exact_tag(self):
        tree, message = self.target("0.11.0")
        self.assertIs(tree, self.pin)
        self.assertIn("unreleased (latest v0.10.0)", message)
        self.assertIn(self.pin.ref, message)
        self.git("update-ref", "refs/tags/v0.11.0", self.release)
        self.addCleanup(self.git, "update-ref", "-d", "refs/tags/v0.11.0")
        tree, message = self.target("0.11.0")
        self.assertIsNot(tree, self.pin)
        self.assertIn("checking release tag v0.11.0", message)
        self.assertEqual(self.findings("import qs.Widgets\nNImage {}\n", tree), set())


if __name__ == "__main__":
    unittest.main()
