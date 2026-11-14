#!/usr/bin/env python3
"""Deterministic publication races against the real raw-profile file owner."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('profile_files', Path(__file__).parents[1] / 'assets/scripts/profile-files.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PublicationRaces(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.config = self.root / 'config'
        self.config.mkdir()
        (self.config / 'settings.json').write_bytes(b'{"before":true}\n')
        self.original = (self.config / 'settings.json').read_bytes()
        source = self.root / 'source'
        source.mkdir()
        (source / 'settings.json').write_bytes(b'{"profile":true}\n')
        self.profile = self.root / 'profile'
        module.snapshot(source, self.profile, {})

    def race(self, callback):
        publish = module.publish
        injected = False

        def publish_then_change(*args, **kwargs):
            nonlocal injected
            result = publish(*args, **kwargs)
            if not injected:
                injected = True
                callback()
            return result

        with patch.object(module, 'publish', publish_then_change):
            with self.assertRaises(module.Refused):
                module.apply(self.profile, self.config, None, self.root / 'evidence')
        self.assertTrue(injected)
        self.assertEqual((self.config / 'settings.json').read_bytes(), self.original)
        results = list((self.root / 'evidence').glob('*/result.json'))
        self.assertEqual(len(results), 1)
        receipt = json.loads(results[0].read_text())
        self.assertEqual(receipt['status'], 'failed')
        self.assertEqual(receipt['rollbackConflicts'], [])
        return results[0].parent

    def created_selected_file(self, name):
        competing = self.config / name

        def create():
            competing.parent.mkdir(parents=True, exist_ok=True)
            competing.write_bytes(b'{"competing":true}\n')

        evidence = self.race(create)
        self.assertEqual(competing.read_bytes(), b'{"competing":true}\n')
        self.assertEqual((evidence / 'observed' / name).read_bytes(), competing.read_bytes())

    def test_created_settings_file(self):
        self.created_selected_file('settings/new.json')

    def test_created_plugin_file(self):
        self.created_selected_file('settings/plugins/new.json')

    def test_complete_inventory_accepts_own_creations_and_removals(self):
        added = self.profile / 'settings/new.json'
        added.parent.mkdir(parents=True)
        added.write_bytes(b'{"added":true}')
        path = self.profile / module.MANIFEST
        manifest = json.loads(path.read_text())
        manifest['entries']['settings/new.json'] = {'present': True, 'sha256': module.digest(added.read_bytes())}
        path.write_text(json.dumps(manifest))
        removed = self.config / 'settings/old.json'
        removed.parent.mkdir(parents=True)
        removed.write_bytes(b'{"removed":true}')
        self.assertEqual(module.apply(self.profile, self.config, None, self.root / 'evidence')['status'], 'applied')
        self.assertEqual((self.config / 'settings/new.json').read_bytes(), added.read_bytes())
        self.assertFalse(removed.exists())

    def test_deletion_preserves_configured_symlink(self):
        target = self.root / 'linked.json'
        target.write_bytes(b'{"linked":true}')
        link = self.config / 'settings/link.json'
        link.parent.mkdir(parents=True)
        link.symlink_to(target)
        self.assertEqual(module.apply(self.profile, self.config, None, self.root / 'evidence')['status'], 'applied')
        self.assertTrue(link.is_symlink())
        self.assertFalse(target.exists())


if __name__ == '__main__':
    unittest.main()
