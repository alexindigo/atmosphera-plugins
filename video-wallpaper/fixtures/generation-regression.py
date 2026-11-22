#!/usr/bin/env python3
"""Real Main, native preferences and FFmpeg generation consumers. Guest only."""
import argparse
import base64
from contextlib import closing, contextmanager
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

CASES = ('failure', 'retry', 'outside', 'replacement', 'disable', 'baseline-retry', 'baseline-obsolete', 'refresh-membership', 'init-retry')


@contextmanager
def recorded_case(output, rows, case):
    row = dict(case=case, status='FAIL', exit=None)
    rows.append(row)
    try:
        yield row
    except BaseException as error:
        row['error'] = type(error).__name__
        raise
    else:
        row['status'] = 'PASS'
    finally:
        (output / 'result.json').write_text(json.dumps(dict(
            status='PASS' if all(r['status'] == 'PASS' for r in rows) else 'FAIL', cases=rows), indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('source', 'plugins', 'guest-profile', 'output'):
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--case', choices=CASES + ('all',), default='all')
    # The guest this profile must describe (the profile itself verifies the live guest).
    parser.add_argument('--expected-guest-uuid', default='12f17a02-25e9-474c-9dae-fea092c2d2be')
    args = parser.parse_args()
    source, plugins, output = (p.resolve() for p in (args.source, args.plugins, args.output))
    sys.path.insert(0, str(source / 'Scripts/dev'))
    from guest_profile import activate_profile
    from probe_files import ProbeFiles
    profile = activate_profile(args.guest_profile.resolve())
    assert profile.uuid == args.expected_guest_uuid and not profile.console.records
    output.mkdir(parents=True, exist_ok=False)
    rows = []

    def run_case(case, row):
        work = output / case
        config = work / 'c'
        preferences = config / 'settings/plugins'
        preferences.mkdir(parents=True)
        (config / 'settings.json').write_text('{"settingsVersion":62}')
        (config / 'plugins.json').write_text('{"version":5,"states":{},"sources":[]}')
        plugin = config / 'plugins/video-wallpaper'
        shutil.copytree(plugins / 'video-wallpaper', plugin)
        path = plugin / 'main/ColorGeneration.qml'
        original = path.read_text()
        assert original.count('id: root') == 1 and original.count('function startColorGen() {') == 1
        instrumented = original.replace('id: root', 'id: root\n    property int reviewAttempts: 0').replace(
            'function startColorGen() {', 'function startColorGen() {\n        root.reviewAttempts++;')
        path.write_text(instrumented)
        (work / 'instrumentation.json').write_text(json.dumps(dict(
            originalSha256=hashlib.sha256(original.encode()).hexdigest(),
            instrumentedSha256=hashlib.sha256(instrumented.encode()).hexdigest(),
            change='counter only; no guards, processes, scheduling or effects changed'), indent=2) + '\n')
        media = work / 'media'
        media.mkdir()
        first, valid, outside = media / 'first.mp4', work / 'valid.mp4', work / 'outside.mp4'
        built = subprocess.run(['ffmpeg', '-nostdin', '-y', '-f', 'lavfi', '-i', 'color=c=black:s=32x32:r=2',
                                '-t', '1', '-c:v', 'mpeg4', str(valid)], capture_output=True, text=True, timeout=20)
        (work / 'media.log').write_text(built.stdout + built.stderr)
        assert built.returncode == 0
        shutil.copy2(valid, outside)
        if case in ('failure', 'retry'):
            first.write_text('invalid real FFmpeg input')
        else:
            shutil.copy2(valid, first)
        if case == 'outside':
            first.unlink()
        image = work / 'original.png'
        image.write_bytes(base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a3ioAAAAASUVORK5CYII='))
        environment = dict(os.environ, **profile.session_environment())
        outputs = json.loads(subprocess.check_output(['niri', 'msg', '--json', 'outputs'], env=environment, text=True, timeout=10))
        name = next(iter(outputs))
        user = preferences / 'video-wallpaper.json'
        initial = json.dumps(dict(enabled=not case.startswith('baseline-'), activeBackend='none',
            wallpapersFolder=str(media), monitors={name: dict(currentWallpaper=str(outside if case in ('outside', 'refresh-membership') else first), noctaliaWallpaper=str(image))}))
        user.write_text(initial)
        cache = work / 'cache'
        cache.mkdir()
        thumbnail_parent = cache / 'images/wallpapers/thumbnails'
        if case == 'init-retry':
            thumbnail_parent.mkdir(parents=True)
            thumbnail_parent.chmod(0o555)
        (cache / 'wallpapers.json').write_text(json.dumps(dict(wallpapers={name: dict(light=str(image), dark=str(image))})))
        binary = work / 'bin'
        binary.mkdir()
        if case in ('replacement', 'disable'):
            shutil.copy2(source / 'Scripts/dev/fixtures/thumbnail-ffmpeg-control.py', binary / 'ffmpeg')
            (binary / 'ffmpeg').chmod(0o755)
        control = work / 'thumbnail-control.json'
        control.write_text('{"calls":0}')
        runtime = profile.child_environment('wpgen-')
        env = dict(os.environ, **runtime, QT_QPA_PLATFORM='wayland', QML_DISABLE_DISK_CACHE='1',
            ATMOSPHERA_CONFIG_DIR=str(config), ATMOSPHERA_SETTINGS_FILE=str(config / 'settings.json'),
            ATMOSPHERA_CACHE_DIR=str(cache), ATMOSPHERA_STATE_DIR=str(work / 'state'),
            WALLPAPER_REVIEW_MANIFEST=(plugin / 'manifest.json').read_text(), WALLPAPER_REVIEW_CASE=case,
            WALLPAPER_REVIEW_WORK=str(work), WALLPAPER_REVIEW_FIRST=str(first), WALLPAPER_REVIEW_OUTSIDE=str(outside),
            WALLPAPER_REVIEW_ORIGINAL=str(image), I5_THUMB_CONTROL=str(control), PATH=str(binary) + os.pathsep + os.environ['PATH'])
        try:
            with closing(ProbeFiles(source, Path(__file__).with_suffix('.qml'))) as probes:
                result = subprocess.run(['timeout', '30', 'dbus-run-session', '--', 'qs', '-p', str(probes.probe), '--no-color'],
                    cwd=source, env=env, capture_output=True, text=True, timeout=40)
                text = result.stdout + result.stderr
                row['exit'] = result.returncode
                (work / 'engine.log').write_text(text)
                print(text, flush=True)
                passed = result.returncode == 0 and 'WALLPAPER_GENERATION: PASS ' + case in text and not any(
                    token in text for token in ('TypeError:', 'ReferenceError:', 'SyntaxError:', '_ASSERT:'))
                if passed and len(rows) == 1:
                    vfs = list((Path(runtime['XDG_RUNTIME_DIR']) / 'quickshell/vfs').iterdir())
                    assert len(vfs) == 1
                    paths = [plugin / name for name in ('Main.qml', 'main/ColorGeneration.qml', 'main/InnerService.qml',
                        'main/Thumbnails.qml', 'common/SaveTimer.qml', 'fixtures/generation-regression.qml')]
                    lint = subprocess.run(['bash', source / 'Scripts/dev/qmllint.sh', *paths, probes.probe], cwd=source,
                        env=dict(env, QS_VFS=str(vfs[0])), capture_output=True, text=True, timeout=60)
                    (work / 'lint.log').write_text(lint.stdout + lint.stderr)
                    assert lint.returncode == 0, (lint.stdout + lint.stderr)[-6000:]
                if passed and case in ('failure', 'retry', 'outside', 'disable', 'refresh-membership', 'init-retry'):
                    assert user.read_text() == initial, 'startup/generation must not publish preferences'
                if passed and case == 'baseline-retry':
                    assert json.loads(user.read_text())['monitors'][name]['noctaliaWallpaper'] == str(image)
                if passed and case in ('retry', 'outside', 'replacement', 'baseline-retry', 'baseline-obsolete', 'refresh-membership', 'init-retry'):
                    selected = media / 'added.mp4' if case == 'refresh-membership' else outside if case in ('outside', 'replacement', 'baseline-obsolete') else first
                    # The consumer publishes its actual ImageCacheService path.
                    observed = json.loads((work / 'observed.json').read_text())
                    assert observed['wallpaper'].endswith('/video-wallpaper/' + selected.name + '.bmp')
                    assert Path(observed['wallpaper']).stat().st_size > 54
                if not passed:
                    raise SystemExit(2)
        finally:
            preferences.chmod(0o755)
            if case == 'init-retry':
                thumbnail_parent.chmod(0o755)
            shutil.rmtree(Path(runtime['XDG_RUNTIME_DIR']))

    for case in CASES if args.case == 'all' else (args.case,):
        with recorded_case(output, rows, case) as row:
            run_case(case, row)
    profile.verify()


if __name__ == '__main__':
    main()
