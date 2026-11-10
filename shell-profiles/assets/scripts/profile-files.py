#!/usr/bin/env python3
"""Raw profile file IO, separate from preference ownership and wallpaper effects.

Cooperative per-target flock matches configqml. Preimages, publication/readback
and rollback evidence are retained; this is not an all-file filesystem CAS.
"""
import argparse
from contextlib import ExitStack, contextmanager
import fcntl
import hashlib
import json
import os
from pathlib import Path
import stat
import sys
import tempfile
import time
import uuid

ROOT_FILES = ('settings.json', 'colors.json', 'plugins.json')
MANIFEST = '_config-files.json'


class Refused(Exception):
    pass


def digest(data):
    return hashlib.sha256(data).hexdigest()


def identity(value):
    return None if value is None else [value.st_dev, value.st_ino, value.st_size,
                                      value.st_mtime_ns, value.st_mode, value.st_uid, value.st_gid, value.st_nlink]


def selected(name):
    path = Path(name)
    if path.is_absolute() or any(part in ('', '.', '..') for part in name.split('/')):
        return False
    parts = path.parts
    return (name in ROOT_FILES or
            (len(parts) in (2, 3) and parts[0] == 'settings' and
             (len(parts) == 2 or parts[1] == 'plugins') and
             parts[-1].endswith('.json') and not parts[-1].startswith('.')))


def inventory(root):
    names = set(ROOT_FILES)
    for directory in (root/'settings', root/'settings/plugins'):
        if directory.exists():
            names.update(str(path.relative_to(root)) for path in directory.iterdir()
                         if path.name.endswith('.json') and not path.name.startswith('.') and not path.is_dir())
    if not all(selected(name) for name in names):
        raise Refused('profile-path')
    return sorted(names)


def file_state(path):
    """Own bytes plus configured-link and referent identity, including absence."""
    try:
        configured = path.lstat()
    except FileNotFoundError:
        configured = None
    resolved = path.resolve(strict=False)
    if configured and not (stat.S_ISREG(configured.st_mode) or stat.S_ISLNK(configured.st_mode)):
        raise Refused('profile-file-type')
    try:
        with resolved.open('rb') as stream:
            before = os.fstat(stream.fileno())
            if not stat.S_ISREG(before.st_mode):
                raise Refused('profile-file-type')
            data = stream.read()
            after = os.fstat(stream.fileno())
    except FileNotFoundError:
        data = None
        before = after = None
    result = dict(configured=identity(configured), target=str(resolved), referent=identity(after),
                  sha256=None if data is None else digest(data))
    if identity(before) != identity(after):
        raise Refused('profile-preimage-conflict')
    # Recheck the name after reading the open file, not merely the fd itself.
    if path.resolve(strict=False) != resolved:
        raise Refused('profile-preimage-conflict')
    try:
        now = path.lstat()
    except FileNotFoundError:
        now = None
    if identity(now) != identity(configured):
        raise Refused('profile-preimage-conflict')
    return result, data


@contextmanager
def lock(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(path, os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
    try:
        if not stat.S_ISREG(os.fstat(fd).st_mode):
            raise Refused('profile-lock-type')
        deadline = time.monotonic()+3
        while True:
            try:
                fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    raise Refused('profile-lock-busy')
                time.sleep(.025)
        yield
    finally:
        os.close(fd)


def locked_files(stack, root, names):
    targets = sorted({str((root/name).resolve(strict=False))+'.lock' for name in names})
    for target in targets:
        stack.enter_context(lock(Path(target)))
    if targets != sorted({str((root/name).resolve(strict=False))+'.lock' for name in names}):
        raise Refused('profile-preimage-conflict')


def write_new(path, data, mode=0o600):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('xb') as stream:
        stream.write(data)
        stream.flush()
        os.fchmod(stream.fileno(), mode)
        os.fsync(stream.fileno())


def json_new(path, value):
    write_new(path, (json.dumps(value, indent=2, sort_keys=True)+'\n').encode())


def capture(root, names):
    return {name: file_state(root/name) for name in names}


def preserve(root, captured, extras=None):
    root.mkdir(mode=0o700)
    for name, (_, data) in captured.items():
        if data is not None:
            write_new(root/name, data)
    manifest = dict(format=2, entries={name: dict(present=data is not None,
                    sha256=None if data is None else digest(data)) for name, (_, data) in captured.items()},
                    sourcePreimages={name: state for name, (state, _) in captured.items()})
    json_new(root/MANIFEST, manifest)
    for name, value in (extras or {}).items():
        json_new(root/name, value)
    return manifest


def snapshot(config, destination, extras):
    destination.parent.mkdir(parents=True, exist_ok=True)
    with ExitStack() as stack:
        stack.enter_context(lock(destination.parent/('.'+destination.name+'.lock')))
        names = inventory(config)
        locked_files(stack, config, names)
        captured = capture(config, names)
        stage = destination.with_name('.'+destination.name+'.pending-'+uuid.uuid4().hex)
        manifest = preserve(stage, captured, extras)
        if inventory(config) != names or capture(config, names) != captured:
            raise Refused('profile-preimage-conflict')
        if destination.is_symlink() or (destination.exists() and not destination.is_dir()):
            raise Refused('profile-destination-type')
        previous = None
        if destination.exists():
            previous = destination.with_name('_retained-'+destination.name+'-'+uuid.uuid4().hex)
            destination.rename(previous)
        try:
            stage.rename(destination)
        except OSError:
            if previous and not destination.exists():
                previous.rename(destination)
            raise
        directory_fd = os.open(destination.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
        return dict(status='saved', files=len(manifest['entries']), retained=str(previous) if previous else None)


def read_profile(profile, current):
    if (profile/MANIFEST).exists():
        manifest = json.loads((profile/MANIFEST).read_bytes())
        if (not isinstance(manifest, dict) or manifest.get('format') != 2 or
                not isinstance(manifest.get('entries'), dict) or
                not all(selected(name) for name in manifest['entries'])):
            raise Refused('profile-manifest')
        desired = {}
        for name, entry in manifest['entries'].items():
            if (not isinstance(entry, dict) or set(entry) != {'present', 'sha256'} or
                    type(entry['present']) is not bool):
                raise Refused('profile-manifest')
            _, data = file_state(profile/name)
            if entry['present'] != (data is not None) or entry['sha256'] != (digest(data) if data is not None else None):
                raise Refused('profile-content-conflict')
            desired[name] = data
        # A v2 snapshot owns the complete selected file family, including absence.
        for name in current:
            desired.setdefault(name, None)
        return desired
    # Original profiles own the three historical root files. A supplied legacy
    # settings.json replaces main settings, so newer sparse main shards must not
    # silently shadow it. Plugin files were not selected by the original format.
    desired = {}
    for name in ROOT_FILES:
        _, data = file_state(profile/name)
        if data is not None:
            desired[name] = data
    if not desired:
        raise Refused('profile-empty')
    if 'settings.json' in desired:
        desired.update({name: None for name in current if len(Path(name).parts) == 2})
    return desired


def publish(path, data, expected, mode, committed=None):
    if file_state(path)[0] != expected:
        raise Refused('profile-preimage-conflict')
    target = Path(expected['target'])
    current = expected['referent']
    if current and (current[5] != os.getuid() or current[7] != 1):
        raise Refused('profile-target-ownership')
    if data is None:
        if current is not None:
            target.unlink()
        after = dict(expected, referent=None, sha256=None)
        if expected['configured'] and not stat.S_ISLNK(expected['configured'][4]):
            after['configured'] = None
        if committed:
            committed(after)
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        fd, temporary = tempfile.mkstemp(prefix='.'+target.name+'.profile-', dir=target.parent)
        try:
            with os.fdopen(fd, 'wb') as stream:
                stream.write(data)
                stream.flush()
                os.fchmod(stream.fileno(), mode)
                os.fsync(stream.fileno())
                staged = identity(os.fstat(stream.fileno()))
            if file_state(path)[0] != expected:
                raise Refused('profile-preimage-conflict')
            os.replace(temporary, target)
            # Record the known committed inode before fsync/readback can fail.
            # Never infer ownership from a later observation of foreign bytes.
            after = dict(expected, referent=staged, sha256=digest(data))
            if not expected['configured'] or not stat.S_ISLNK(expected['configured'][4]):
                after['configured'] = staged
            if committed:
                committed(after)
        finally:
            if os.path.lexists(temporary):
                os.unlink(temporary)
    parent = os.open(target.parent, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(parent)
    finally:
        os.close(parent)
    observed, readback = file_state(path)
    if observed != after or readback != data:
        raise Refused('profile-readback-conflict')
    return after


def apply(profile, config, baseline, evidence):
    if not profile.is_dir():
        raise Refused('profile-missing')
    evidence.mkdir(parents=True, exist_ok=True)
    operation = evidence/uuid.uuid4().hex
    operation.mkdir(mode=0o700)
    with ExitStack() as stack:
        stack.enter_context(lock(profile.parent/('.'+profile.name+'.lock')))
        current = inventory(config)
        desired = read_profile(profile, current)
        names = sorted(desired)
        locked_files(stack, config, names)
        captured = capture(config, names)
        preserve(operation/'before', captured)
        if baseline:
            expected = json.loads((baseline/MANIFEST).read_bytes())['sourcePreimages']
            if inventory(config) != sorted(expected) or any(file_state(config/name)[0] != state for name, state in expected.items()):
                json_new(operation/'result.json', dict(status='failed', error='profile-preimage-conflict'))
                raise Refused('profile-preimage-conflict')
        published = {}
        try:
            for name in names:
                before, data = captured[name]
                if data == desired[name]:
                    continue
                mode = stat.S_IMODE(before['referent'][4]) if before['referent'] else 0o600
                publish(config/name, desired[name], before, mode,
                        lambda state, name=name: published.__setitem__(name, state))
            # Include every unchanged selected preimage and the profile input in
            # the closing check, not just the last replaced file.
            if read_profile(profile, current) != desired:
                raise Refused('profile-content-conflict')
            for name in names:
                expected = published.get(name, captured[name][0])
                if file_state(config/name)[0] != expected:
                    raise Refused('profile-readback-conflict')
            receipt = dict(status='applied', files=len(names), evidence=str(operation))
            json_new(operation/'result.json', receipt)
            return receipt
        except (OSError, Refused) as error:
            conflicts = []
            for name in reversed(published):
                original, data = captured[name]
                try:
                    mode = stat.S_IMODE(original['referent'][4]) if original['referent'] else 0o600
                    publish(config/name, data, published[name], mode)
                    if data is not None and original['referent']:
                        os.utime(Path(original['target']), ns=(time.time_ns(), original['referent'][3]))
                except (OSError, Refused):
                    conflicts.append(name)
            # Competing bytes are retained, never overwritten to force rollback.
            preserve(operation/'observed', capture(config, names))
            json_new(operation/'result.json', dict(status='failed', error=str(error) if isinstance(error, Refused) else 'profile-io',
                                                  rollbackConflicts=conflicts))
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=('save', 'apply'))
    parser.add_argument('config', type=Path)
    parser.add_argument('profile', type=Path)
    parser.add_argument('--baseline', type=Path)
    parser.add_argument('--evidence', type=Path)
    parser.add_argument('--wallpapers')
    parser.add_argument('--meta')
    args = parser.parse_args()
    try:
        if not args.config.is_absolute() or not args.profile.is_absolute():
            raise Refused('profile-path')
        if args.operation == 'save':
            extras = {name: json.loads(value) for name, value in (('wallpapers.json', args.wallpapers), ('meta.json', args.meta)) if value is not None}
            result = snapshot(args.config, args.profile, extras)
        else:
            result = apply(args.profile, args.config, args.baseline,
                           args.evidence or args.config/'.profile-operations')
        print(json.dumps(result, sort_keys=True))
    except (OSError, ValueError, KeyError, Refused):
        # Never print settings content or a filesystem exception containing it.
        print('profile-files-failed', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
