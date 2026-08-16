# atmosphera-plugins

Curated plugin registry for the [Atmosphera](https://github.com/alexindigo/atmosphera)
shell — a full mirror of the upstream
[Noctalia plugins](https://github.com/noctalia-dev/noctalia-plugins) registry,
converted for the Atmosphera widget API.

## What's here

Top-level directories are plugins (one per id, per the registry contract); the
`registry.json` at the root is what the shell's plugin system fetches.

**All 132 upstream plugins** are mirrored here, converted. Most needed no
changes; the ones referencing the renamed icon widgets got the mechanical
rename below.

## The conversion

Atmosphera renamed the Noctalia icon widgets: `NIcon` → `AtmoIcon`,
`NIconButton` → `AtmoIconButton`, `NIconButtonHot` → `AtmoIconButtonHot`,
`NIconPicker` → `AtmoIconPicker`. Everything else (`NBox`, `NText`, `NToggle`,
services, `Icon.*`, `Style.*`, `Color.*`) is API-identical.

Conversions are verbatim upstream + that rename. When upstream updates a plugin,
re-copy the directory and re-apply the rename:

```sh
sed -i -E 's/\bNIconButtonHot\b/AtmoIconButtonHot/g; s/\bNIconButton\b/AtmoIconButton/g; s/\bNIconPicker\b/AtmoIconPicker/g; s/\bNIcon\b/AtmoIcon/g' <plugin>/**/*.qml
```

## Licensing

Each plugin retains its upstream license (see its `manifest.json`; upstream
plugins are mostly MIT by their respective authors — `kde-connect` is GPLv2 by
WerWolv, vendored with its LICENSE). Registry tooling text in this repo is
GPL-3.0 (see LICENSE).
