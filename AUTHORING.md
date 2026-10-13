# Authoring Atmosphera plugins

## Palette and types

Use `AtmoColor.<member>` for Atmosphera's palette and helpers, with
`import qs.Commons`. Never use bare `Color` for the palette: on Qt 6.12+
it resolves to QtQuick's utility singleton. `AtmoColor` requires Atmosphera
0.8.0 or newer.

Use only members declared on the singleton in the shell checkout's
`Commons/AtmoColor.qml`. As of Atmosphera 0.8.0, its root members are:

| # | Kind | Members |
|---|---|---|
| 1 | Accent colours | `mPrimary`, `mOnPrimary`, `mSecondary`, `mOnSecondary`, `mTertiary`, `mOnTertiary` |
| 2 | Error colours | `mError`, `mOnError` |
| 3 | Surface colours | `mSurface`, `mOnSurface`, `mSurfaceVariant`, `mOnSurfaceVariant` |
| 4 | Outline, shadow and hover colours | `mOutline`, `mShadow`, `mHover`, `mOnHover` |
| 5 | Model and transition state | `colorKeyModel`, `reloadColors`, `skipTransition`, `isTransitioning` |
| 6 | Colour-key helpers | `resolveColorKey(key)`, `resolveOnColorKey(key)`, `resolveColorKeyOptional(key)` |
| 7 | Opacity helpers | `adaptiveOpacity(baseOpacity)`, `smartAlpha(baseColor, minAlpha = 0.4)` |
| 8 | Shell reload/transition functions | `scheduleExternalColorReload()`, `startTransition()` |

The presence of a Material Design name elsewhere does not make it a palette
member. Check the actual declaration before using it; nested implementation
objects are not the singleton's public members.

Atmosphera-specific widget and type names follow the `Atmo*` convention.
Current examples include `AtmoIcon`, `AtmoIconButton`, `AtmoIconButtonHot`,
`AtmoIconPicker`, `AtmoIconColorizeEffect`, `AtmoFilePicker`,
`AtmoWidgetAppearance`, `AtmoWallpaperBackground`, `AtmoAppIcon` and
`AtmoSingletonCheck`. Use the names provided by the target shell version.

## Versions and compatibility

Every behaviour change requires a version bump in **both** `manifest.json`
and the plugin's `registry.json` entry. The shell offers an update only when
the index version is higher than the installed version; CI requires the
manifest and index versions to match.

Set `minAtmospheraVersion` to the lowest shell version whose APIs you use,
in both the manifest and index. Plugins using `AtmoColor` must require at
least `"0.8.0"`. The shell gates installs and updates using the index.
Index versions and minimum versions must be plain `x.y.z`, without a `v`
prefix or prerelease suffix.

## Checks and test environment

Run these checks against your plugin using the target Atmosphera checkout's
identifier tool:

```sh
python3 <atmosphera-checkout>/Scripts/dev/qml-identifiers.py shadowing \
  --root <atmosphera-checkout> <plugin-dir>
python3 <atmosphera-checkout>/Scripts/dev/qml-identifiers.py rename \
  --from Color --to AtmoColor --check <plugin-dir>
```

The shadowing check reports Atmosphera names hidden by imported Qt or
Quickshell modules; expect no `AtmoColor`/`Color` findings. The rename check
must report **0 pending** code references.

Test plugins and run these checks only in an isolated test environment, never
on a live desktop shell. Load each declared entry point on the target shell
version and inspect its logs and rendered surfaces before publishing.

### Commit-time compatibility gate

The tracked pre-commit hook checks the staged Git index with the Atmosphera
shell's checker, at the shell commit pinned in `.github/atmosphera-ref`. It
checks each changed plugin's QML compatibility and version bump, and audits every
plugin. CI runs the same runner alongside the registry validator.

See [LINTING.md](LINTING.md) for hook setup, the pinned shell, full-audit
commands and the CI workflow. A code or asset change must increase the
plugin's version in both the manifest and catalog; retaining the old version
prevents existing installations receiving corrected code.
