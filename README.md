# atmosphera-plugins

Curated plugin registry for [Atmosphera](https://github.com/alexindigo/atmosphera),
including converted [Noctalia plugins](https://github.com/noctalia-dev/noctalia-plugins),
vendored contributions and Atmosphera-native plugins.

Each top-level plugin directory has a `manifest.json`. The root `registry.json`
is the catalog fetched by the shell. Preserve upstream authorship and licenses
when adapting a plugin; native additions declare their own author and license.
The catalog's `official` flag is a maintainer designation, not an installation
requirement. Plugins marked `official: false` appear under **Available → All**
or **Not Downloaded**, but not under the **Official** filter.

## Target shell and supported APIs

The compatibility gate targets **Atmosphera 0.8.0**. Plugins using its palette
must declare `minAtmospheraVersion: "0.8.0"` in both their manifest and catalog.

- Import `qs.Commons` for `AtmoColor`, `Style`, `Settings` and other common services.
- Import `qs.Widgets` for shared widgets. Use `AtmoIcon`, `AtmoIconButton`,
  `AtmoIconButtonHot`, `AtmoIconPicker` and `AtmoFilePicker`, not their retired
  `NIcon*`/`NFilePicker` names. Widgets such as `NText` and `NBox` retain their names.
- Use `AtmoColor`, never bare `Color`, for the palette. Qt 6.12 exports a different
  `Color` singleton that can silently capture old references.
- Check the target shell's `Commons/AtmoColor.qml` and `Commons/Style.qml` before
  using a member. Material Design names such as `mPrimaryContainer`, `mWarning`
  and `mOutlineVariant` are **not** automatically available in Atmosphera.
  Nested implementation objects are not public singleton API.
- Theme surfaces with `mSurface`/`mSurfaceVariant`, text with `mOnSurface`/
  `mOnSurfaceVariant`, and outlines with `mOutline`. For a subtle selection,
  use `Qt.tint(AtmoColor.mSurfaceVariant, Qt.alpha(AtmoColor.mPrimary, 0.16))`.
  Use supported accent/error colors or an explicitly chosen severity color.
- Prefer `Style.fontSizeS`, `Style.radiusM`, `Style.borderS` and content-derived
  dimensions. The default font is `Settings.data.ui.fontDefault`. Bar widgets
  should use per-screen capsule sizing instead of assuming one global density.
- Import a service from its actual module, such as `qs.Services.UI` or
  `qs.Services.Compositor`. Old `qs.Services.Noctalia`, `qs.Common` and DMS-only
  `qs.Modules.Plugins` imports do not exist on this track.

See [AUTHORING.md](AUTHORING.md) for the palette member reference and
[LINTING.md](LINTING.md) for the commit gate's precise scope and setup.

## Create a new plugin

### 1. Choose an ID and create the directory

Use a unique, lowercase kebab-case ID, for example `hello-plugin`. The directory
name, manifest `id` and registry entry `id` must agree. A minimal bar plugin is:

```text
hello-plugin/
├── manifest.json
├── BarWidget.qml
├── README.md
└── LICENSE
```

Create and test this source in an isolated test environment. Do not experiment on
a live desktop profile. The examples below form a complete minimal bar plugin;
replace the author/repository placeholders before publishing.

### 2. Write `manifest.json`

```json
{
  "id": "hello-plugin",
  "name": "Hello Plugin",
  "version": "0.1.0",
  "minAtmospheraVersion": "0.8.0",
  "author": "Your Name",
  "license": "MIT",
  "repository": "https://github.com/OWNER/PLUGIN-REPO",
  "description": "A minimal bar button demonstrating plugin settings.",
  "tags": ["Bar"],
  "entryPoints": {
    "barWidget": "BarWidget.qml"
  },
  "metadata": {
    "defaultSettings": {
      "clicks": 0
    }
  }
}
```

Entry points are relative to the plugin directory and must exist. Declare only
the components you implement. Versions and minimum versions are plain `x.y.z`,
without a `v` prefix or prerelease suffix.

### 3. Implement `BarWidget.qml`

```qml
import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

AtmoIconButton {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  baseSize: Style.getCapsuleHeightForScreen(screen ? screen.name : "")
  applyUiScale: false
  customRadius: Style.radiusL
  colorBg: Style.capsuleColor
  colorFg: AtmoColor.mOnSurface
  colorBorder: "transparent"
  colorBorderHover: "transparent"
  border.color: Style.capsuleBorderColor
  border.width: Style.capsuleBorderWidth
  icon: "bell"
  tooltipText: "Hello Plugin"
  tooltipDirection: BarService.getTooltipDirection(screen ? screen.name : "")

  onClicked: {
    if (!pluginApi)
      return;
    const clicks = (pluginApi.pluginSettings.clicks || 0) + 1;
    pluginApi.pluginSettings.clicks = clicks;
    pluginApi.saveSettings();
    ToastService.showNotice("Hello Plugin", "Clicks: " + clicks);
  }
}
```

The shell injects `pluginApi` and the bar placement properties. Keep persistent
settings in `pluginApi.pluginSettings`, with defaults declared in the manifest,
and call `pluginApi.saveSettings()` after changing them. Avoid machine-specific
home paths; use `Quickshell.env("HOME")` or appropriate XDG locations.

### 4. Add the matching catalog entry

Add an object to the root `registry.json` `plugins` array:

```json
{
  "id": "hello-plugin",
  "name": "Hello Plugin",
  "author": "Your Name",
  "description": "A minimal bar button demonstrating plugin settings.",
  "license": "MIT",
  "version": "0.1.0",
  "tags": ["Bar"],
  "repository": "https://github.com/OWNER/PLUGIN-REPO",
  "official": false,
  "lastUpdated": "2026-10-11",
  "minAtmospheraVersion": "0.8.0"
}
```

Use the actual current date for `lastUpdated`. The version and minimum-version
fields must match the manifest. The shell gates installation using the catalog
before downloading the manifest; a minimum declared only in the manifest is
insufficient.

### 5. Extend it when needed

| Entry point | Typical use and contract |
|---|---|
| `main` | One shared `Main.qml` instance for processes/state; declare `property var pluginApi: null`. UI components access it through `pluginApi.mainInstance`. |
| `barWidget` | Per-screen bar component; use the placement properties shown above. |
| `panel` | On-demand panel; declare `pluginApi`, `screen`, `contentPreferredWidth` and `contentPreferredHeight`. Open it with `pluginApi.togglePanel(screen, button)`. |
| `settings` | Plugin settings editor; persist through `pluginApi.pluginSettings` and `saveSettings()`. |
| `desktopWidget` | Desktop component using the shell's desktop-widget contract; inspect a current native example before implementing. |
| `lockScreen` | Specialized lockscreen view with the required `lockContext`; validate it in an isolated test session. |

Use `i18n/en.json` and `pluginApi.tr("key")` for translated UI, then add other
locales as needed. Document external tools/permissions in the plugin README.
Invoke processes with argument arrays and report failures; do not automatically
install dependencies, alter privileged permissions or restart the desktop.

Examples to inspect: [touchpad-incident](touchpad-incident/) for a shared process
and bar frontend, and [digest-watcher](digest-watcher/) for a bar button and panel.

### 6. Validate, test and publish

Stage the plugin changes, then run the shell's plugin runner from a checkout of
the Atmosphera shell at the commit in `.github/atmosphera-ref`. It validates the
registry, checks changed plugins and audits every plugin:

```sh
Scripts/dev/plugin-lint-repo.sh /path/to/atmosphera-plugins HEAD
```

Also run the shell's QML lint tooling (`Scripts/dev/qmllint.sh`). Load
every declared entry point in a disposable profile and check logs, light/dark
themes, scaling and the relevant interactions. Static checks do not prove
external integrations or dynamically generated QML work.

Activate the tracked commit hook as described in [LINTING.md](LINTING.md).
It checks the Git index (staged content, including partially staged files) and
blocks an incompatible plugin or missing version bump. CI runs the same runner
against the pinned shell. Review the diff, stage the intended files, commit and
publish through the project's normal review process.

For existing plugins, increment the version in **both** the manifest and catalog
for code/asset changes, update `lastUpdated`, and adjust the matching minimum
versions if newer APIs are used. Keeping the old version prevents existing users
receiving the corrected files—even when the shell package itself is upgraded.

## Updating a converted upstream plugin

Keep the upstream source/license attribution, then apply only the required
Atmosphera adaptations. Use the target shell's token-aware identifier tool
rather than replacing text inside strings/comments:

```sh
python3 /path/to/atmosphera/Scripts/dev/qml-identifiers.py rename --from NIcon --to AtmoIcon PLUGIN_DIR
python3 /path/to/atmosphera/Scripts/dev/qml-identifiers.py rename --from NIconButton --to AtmoIconButton PLUGIN_DIR
python3 /path/to/atmosphera/Scripts/dev/qml-identifiers.py rename --from NIconButtonHot --to AtmoIconButtonHot PLUGIN_DIR
python3 /path/to/atmosphera/Scripts/dev/qml-identifiers.py rename --from NIconPicker --to AtmoIconPicker PLUGIN_DIR
python3 /path/to/atmosphera/Scripts/dev/qml-identifiers.py rename --from NFilePicker --to AtmoFilePicker PLUGIN_DIR
python3 /path/to/atmosphera/Scripts/dev/qml-identifiers.py rename --from Color --to AtmoColor PLUGIN_DIR
```

Renaming alone does not validate service imports, widget properties or palette
members. Run the full checks above, verify the declared entry points and bump
the plugin release metadata.

## Registry compatibility and licensing

- Every catalog ID has one top-level payload/manifest, and vice versa.
- `minNoctaliaVersion` and `minAtmospheraVersion`, when declared, match in both
  files. Atmosphera's Noctalia compatibility track supports major versions up
  to **4**; native plugins can declare the real Atmosphera minimum instead.
- Preserve upstream licenses. Most mirrored plugins are MIT; `kde-connect`
  retains WerWolv's GPLv2 license and its LICENSE file. New plugins include an
  appropriate license file and matching manifest identifier.
- Registry tooling/text is GPL-3.0; see [LICENSE](LICENSE).
