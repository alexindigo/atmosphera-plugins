# Plugin compatibility gate

The plugin compatibility gate is the Atmosphera shell's own checker,
`Scripts/dev/plugin-lint.py`, run by the shell's runner
`Scripts/dev/plugin-lint-repo.sh`. This repository pins the shell commit it uses
in `.github/atmosphera-ref`. The same runner backs the local commit hook and CI.

The gate reads Git content only. It never formats files, stages files or
launches a shell. Diagnostics contain paths and line numbers; a failure blocks
the commit or the CI job.

## What it checks

- Missing `qs.*` imports and retired Atmosphera widget names.
- `Color` palette references and imported-module name shadowing, using the
  target shell's comment/string/template/regex-aware identifier lexer.
- Public root members of `AtmoColor` and `Style` against the target shell.
- Existing entry-point files (or wallpaper directories), safe paths, minimum
  Atmosphera version. A plugin using `AtmoColor` must declare at least `0.8.0`.
- Manifest/catalog membership, duplicate IDs and matching versions/minimums.
- A strictly higher plugin version when staged runtime code, assets or manifest
  changes. Documentation-only changes do not require a version bump.

Compatibility checks run over every source file in each changed plugin, so
updating a broken plugin requires fixing its compatibility problems too.
Catalog consistency is checked repository-wide. Every run also audits all
plugins, so a shell API change needs a full audit in addition to per-commit
checks.

This gate complements `qmllint`, formatting and runtime tests. It does not
prove all QML bindings, optional third-party modules, dynamically computed member
names or privileged helpers work. Running it does not repair any installed
plugin on disk.

## Requirements

- Git and a container engine. Podman is preferred; Docker is used when Podman
  is absent. `ATMOSPHERA_CONTAINER_ENGINE=podman` or `=docker` selects one
  explicitly. Once selected, an engine failure is a failure: there is no
  fallback to the other engine.
- The first run clones the pinned shell and may build the shell's dev image.
  Later runs reuse both.

## Pinned shell and local source

`.github/atmosphera-ref` holds the full commit SHA of the Atmosphera shell that
supplies the checker, lexer and `AtmoColor`/`Style` declarations. The hook reads
this file from the **Git index**, so a commit that changes the pin is checked
against the new pin.

The hook clones the shell from `https://github.com/alexindigo/atmosphera` into
`atmosphera-shell/<sha>` under the repository's common Git directory, then
checks out the pin. To use a local shell repository instead, set:

```sh
export ATMOSPHERA_SHELL_SRC=/path/to/local/atmosphera
```

That repository must contain the pinned commit.

## Commit hook

Activate the tracked hook in this clone:

```sh
git config core.hooksPath .githooks
```

Do not overwrite an existing `core.hooksPath` or a developer's own hooks; merge
the call into the existing hook instead. The tracked hook does the following:

1. Reads the index tree with `git write-tree`, which fails for an unmerged index.
2. Rejects symlink and submodule inputs, which the archive cannot represent.
3. Extracts the index tree and `HEAD` into a temporary snapshot and removes it on exit.
4. Runs the shell's runner in the container. It validates the registry, checks
   changed plugins against `HEAD` and audits every plugin.

If the pin cannot be read, the shell cannot be fetched, or no engine is
available, the hook fails with setup guidance. Setup and validation never commit,
stage or push anything.

## CI

`.github/workflows/validate-registry.yml` runs on pushes and pull requests to
`master`. It checks out the pinned shell into `.tooling/atmosphera` and runs:

- the shell's checker regression tests, `Scripts/dev/plugin-lint-selftest.py`,
  through its container launcher;
- `Scripts/dev/plugin-lint-repo.sh "$GITHUB_WORKSPACE" "$BASE_REF"`.

`BASE_REF` is the pull request base, else the previous push, else `HEAD^`. The
hook compares against `HEAD` instead. Both use the same runner.

## Running the checks by hand

From a checkout of the Atmosphera shell at the pinned commit, check the staged
content of the plugins repository:

```sh
Scripts/dev/plugin-lint-repo.sh /path/to/atmosphera-plugins HEAD
```

The runner always performs the full audit as well, so the same command reports
problems in plugins you did not change.

## Moving the pin

Use this when plugins need a newer shell API:

1. Choose the shell commit and confirm it contains the required API.
2. Write its full SHA into `.github/atmosphera-ref` and stage that file.
3. Commit the pin change. The hook reads the pin from the index and runs
   the full audit with the new checker, so any new finding blocks that commit
   until it is fixed.
