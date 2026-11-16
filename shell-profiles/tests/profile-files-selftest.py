#!/usr/bin/env python3
"""Deterministic publication races against the real raw-profile file owner."""
import importlib.util
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('profile_files', Path(__file__).parents[1] / 'assets/scripts/profile-files.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ProfileFixture(unittest.TestCase):
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


class PublicationRaces(ProfileFixture):
    def test_two_argument_entrypoints_save_apply_valid_wallpaper_metadata(self):
        scripts = Path(module.__file__).parent
        saved = self.root / 'two-argument-profile'
        result = subprocess.run(['sh', str(scripts/'save-profile.sh'), str(self.config), str(saved)],
                                capture_output=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)['status'], 'saved')
        wallpapers = json.loads((saved/'wallpapers.json').read_bytes())
        self.assertEqual(wallpapers, {'screens': []})
        (self.config/'settings.json').write_bytes(b'{"later":true}')
        applied = subprocess.run(['sh', str(scripts/'apply-profile.sh'), str(saved), str(self.config)],
                                 capture_output=True, timeout=5)
        self.assertEqual(applied.returncode, 0, applied.stderr)
        self.assertEqual(json.loads(applied.stdout)['status'], 'applied')
        self.assertEqual((self.config/'settings.json').read_bytes(), self.original)

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

    def test_malformed_closing_profile_rolls_back(self):
        def corrupt_manifest():
            (self.profile / module.MANIFEST).write_bytes(b'{')

        try:
            self.race(corrupt_manifest)
        finally:
            self.assertEqual((self.config / 'settings.json').read_bytes(), self.original)

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


class AliasedTargets(ProfileFixture):
    def setUp(self):
        super().setUp()
        (self.config / 'settings').mkdir()
        (self.config / 'settings.json').unlink()
        self.target = self.config / 'settings/main.json'
        self.target.write_bytes(b'{"saved":true}\n')
        self.target.chmod(0o640)
        (self.config / 'settings.json').symlink_to('settings/main.json')
        (self.config / 'colors.json').symlink_to('settings/main.json')
        self.aliased_profile = self.root / 'aliased-profile'
        module.snapshot(self.config, self.aliased_profile, {})
        self.saved = self.target.read_bytes()
        self.target.write_bytes(b'{"current":true}\n')
        self.original = self.target.read_bytes()
        self.baseline = self.root / 'baseline'
        module.snapshot(self.config, self.baseline, {})

    def publish_calls(self, callback):
        calls = []
        publish = module.publish

        def observed(path, *args, **kwargs):
            calls.append(str(path))
            return publish(path, *args, **kwargs)

        with patch.object(module, 'publish', observed):
            callback()
        return calls

    def check_links(self):
        for name in ('settings.json', 'colors.json'):
            self.assertTrue((self.config / name).is_symlink())
            self.assertEqual(os.readlink(self.config / name), 'settings/main.json')

    def test_saved_aliases_apply_once_with_baseline(self):
        def apply():
            self.assertEqual(module.apply(self.aliased_profile, self.config, self.baseline,
                                          self.root / 'evidence')['status'], 'applied')

        calls = self.publish_calls(apply)
        self.assertEqual(len(calls), 1)
        self.assertEqual(self.target.read_bytes(), self.saved)
        self.assertEqual(stat.S_IMODE(self.target.stat().st_mode), 0o640)
        self.check_links()

    def test_alias_capture_refuses_mixed_physical_preimages(self):
        file_state = module.file_state
        foreign = b'{"foreign":true}'
        changed = False

        def change_between_aliases(path):
            nonlocal changed
            result = file_state(path)
            if not changed and path == self.config / 'colors.json':
                changed = True
                self.target.write_bytes(foreign)
            return result

        with patch.object(module, 'file_state', change_between_aliases):
            with self.assertRaisesRegex(module.Refused, 'profile-preimage-conflict'):
                module.capture(self.config, module.inventory(self.config))
        self.assertTrue(changed)
        self.assertEqual(self.target.read_bytes(), foreign)
        self.check_links()

    def test_conflicting_alias_contents_refuse_before_publication(self):
        # An earlier, independent target must not publish before a later alias
        # conflict is discovered by the complete physical-target plan.
        (self.config / 'colors.json').unlink()
        colors = b'{"independent":true}'
        (self.config / 'colors.json').write_bytes(colors)
        content = b'{"different":true}'
        (self.aliased_profile / 'settings.json').write_bytes(content)
        manifest_path = self.aliased_profile / module.MANIFEST
        manifest = json.loads(manifest_path.read_bytes())
        manifest['entries']['settings.json']['sha256'] = module.digest(content)
        manifest_path.write_text(json.dumps(manifest))

        def apply():
            with self.assertRaisesRegex(module.Refused, 'profile-alias-conflict'):
                module.apply(self.aliased_profile, self.config, None, self.root / 'evidence')

        self.assertEqual(self.publish_calls(apply), [])
        self.assertEqual(self.target.read_bytes(), self.original)
        self.assertEqual((self.config / 'colors.json').read_bytes(), colors)
        self.assertTrue((self.config / 'settings.json').is_symlink())

    def test_closing_failure_rolls_back_one_physical_target(self):
        read_profile = module.read_profile
        reads = 0

        def changed_profile(*args):
            nonlocal reads
            reads += 1
            if reads == 2:
                raise module.Refused('profile-content-conflict')
            return read_profile(*args)

        def apply():
            with patch.object(module, 'read_profile', changed_profile):
                with self.assertRaisesRegex(module.Refused, 'profile-content-conflict'):
                    module.apply(self.aliased_profile, self.config, None, self.root / 'evidence')

        self.assertEqual(len(self.publish_calls(apply)), 2)
        self.assertEqual(self.target.read_bytes(), self.original)
        self.check_links()
        receipt = json.loads(next((self.root / 'evidence').glob('*/result.json')).read_bytes())
        self.assertEqual(receipt['rollbackConflicts'], [])

    def test_post_rename_failure_keeps_alias_rollback_witness(self):
        fsync = module.os.fsync
        injected = False

        def fail_directory(fd):
            nonlocal injected
            if not injected and stat.S_ISDIR(os.fstat(fd).st_mode):
                injected = True
                raise OSError('directory sync fault')
            return fsync(fd)

        # Fail only after the immutable before-evidence has been retained.
        publish = module.publish

        def fail_after_rename(*args, **kwargs):
            with patch.object(module.os, 'fsync', fail_directory):
                return publish(*args, **kwargs)

        with patch.object(module, 'publish', fail_after_rename):
            with self.assertRaises(OSError):
                module.apply(self.aliased_profile, self.config, None, self.root / 'evidence')
        self.assertTrue(injected)
        self.assertEqual(self.target.read_bytes(), self.original)
        self.check_links()
        receipt = json.loads(next((self.root / 'evidence').glob('*/result.json')).read_bytes())
        self.assertEqual(receipt['rollbackConflicts'], [])

    def test_alias_deletion_and_recreation(self):
        self.target.unlink()
        absent = self.root / 'absent-profile'
        module.snapshot(self.config, absent, {})
        self.target.write_bytes(self.original)
        self.assertEqual(module.apply(absent, self.config, None, self.root / 'delete-evidence')['status'], 'applied')
        self.assertFalse(self.target.exists())
        self.check_links()
        self.assertEqual(module.apply(self.aliased_profile, self.config, None, self.root / 'create-evidence')['status'], 'applied')
        self.assertEqual(self.target.read_bytes(), self.saved)
        self.check_links()


class LegacyRootAliases(ProfileFixture):
    def test_explicit_legacy_root_alias_conflict_refuses_without_publication(self):
        (self.config/'settings').mkdir()
        target = self.config/'settings/main.json'
        target.write_bytes(self.original)
        (self.config/'settings.json').unlink()
        (self.config/'settings.json').symlink_to('settings/main.json')
        (self.config/'colors.json').symlink_to('settings/main.json')
        legacy = self.root/'conflicting-legacy'
        legacy.mkdir()
        (legacy/'settings.json').write_bytes(b'{"settings":true}')
        (legacy/'colors.json').write_bytes(b'{"colors":true}')
        with self.assertRaisesRegex(module.Refused, 'profile-alias-conflict'):
            module.apply(legacy, self.config, None, self.root/'conflict-evidence')
        self.assertEqual(target.read_bytes(), self.original)
        for name in ('settings.json', 'colors.json'):
            self.assertTrue((self.config/name).is_symlink())
            self.assertEqual(os.readlink(self.config/name), 'settings/main.json')

    def test_legacy_root_restore_preserves_its_shard_aliases(self):
        legacy = self.root/'legacy'
        legacy.mkdir()
        saved = b'{"restored":true}\n'
        (legacy/'settings.json').write_bytes(saved)
        for layout in ('relative', 'absolute', 'multiple', 'missing'):
            with self.subTest(layout=layout):
                config = self.root/layout
                (config/'settings/plugins').mkdir(parents=True)
                target = config/'settings/main.json'
                if layout != 'missing':
                    target.write_bytes(self.original)
                    target.chmod(0o640)
                root_link = config/'settings.json'
                root_link.symlink_to(target if layout == 'absolute' else 'settings/main.json')
                original_link = os.readlink(root_link)
                alias = config/'settings/alias.json'
                if layout == 'multiple':
                    alias.symlink_to('main.json')
                stale = config/'settings/audio.json'
                stale.write_bytes(b'{"stale":true}')
                plugin = config/'settings/plugins/keep.json'
                plugin.write_bytes(b'{"plugin":true}')
                baseline = self.root/(layout+'-baseline')
                module.snapshot(config, baseline, {})
                result = module.apply(legacy, config, baseline, self.root/(layout+'-evidence'))
                self.assertEqual(result['status'], 'applied')
                self.assertTrue(root_link.is_symlink())
                self.assertEqual(os.readlink(root_link), original_link)
                self.assertEqual(root_link.read_bytes(), saved)
                self.assertEqual(target.read_bytes(), saved)
                self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600 if layout == 'missing' else 0o640)
                if layout == 'multiple':
                    self.assertTrue(alias.is_symlink())
                    self.assertEqual(os.readlink(alias), 'main.json')
                    self.assertEqual(alias.read_bytes(), saved)
                self.assertFalse(stale.exists())
                self.assertEqual(plugin.read_bytes(), b'{"plugin":true}')
                cold = subprocess.run([sys.executable, '-B', '-c',
                    'import json,sys;from pathlib import Path;assert json.loads(Path(sys.argv[1]).read_bytes())=={"restored":True}',
                    str(root_link)], capture_output=True, timeout=5)
                self.assertEqual(cold.returncode, 0, cold.stderr)


class SpecialReferents(ProfileFixture):
    def command(self, operation, profile, *options):
        return subprocess.run([sys.executable, str(Path(module.__file__)), operation,
                               str(self.config), str(profile), *map(str, options)],
                              capture_output=True, timeout=3)

    def test_symlink_to_fifo_refuses_without_waiting_for_writer(self):
        fifo = self.root / 'fifo'
        os.mkfifo(fifo)
        (self.config / 'settings').mkdir()
        (self.config / 'settings/link.json').symlink_to(fifo)
        result = self.command('save', self.root / 'fifo-profile')
        self.assertEqual(result.returncode, 1)
        self.assertIn(b'profile-files-failed', result.stderr)
        self.assertEqual((self.config / 'settings.json').read_bytes(), self.original)

    def test_fifo_profile_manifest_refuses_without_waiting(self):
        manifest = self.profile / module.MANIFEST
        manifest.unlink()
        os.mkfifo(manifest)
        self.assertEqual(self.command('apply', self.profile).returncode, 1)
        self.assertEqual((self.config / 'settings.json').read_bytes(), self.original)

    def test_fifo_baseline_manifest_refuses_without_waiting(self):
        baseline = self.root / 'baseline'
        baseline.mkdir()
        os.mkfifo(baseline / module.MANIFEST)
        self.assertEqual(self.command('apply', self.profile, '--baseline', baseline).returncode, 1)
        self.assertEqual((self.config / 'settings.json').read_bytes(), self.original)

    def test_invalid_baseline_manifest_reports_without_traceback(self):
        baseline = self.root / 'baseline'
        baseline.mkdir()
        for body in (b'null', b'[]', b'{}', b'{'):
            with self.subTest(body=body):
                (baseline / module.MANIFEST).write_bytes(body)
                result = self.command('apply', self.profile, '--baseline', baseline)
                self.assertEqual(result.returncode, 1)
                self.assertEqual(result.stderr, b'profile-files-failed\n')
                self.assertEqual((self.config / 'settings.json').read_bytes(), self.original)


if __name__ == '__main__':
    unittest.main()
