#!/usr/bin/env python3
"""Check statically resolvable QML shell dependencies at declared version floors.

The pin supplies the lexer and identifies shell symbols. Release trees are read
as data, never imported or executed. The ordinary pinned compatibility lint
still checks unknown identifiers/types and non-shell imports.
"""

import argparse
import importlib
import json
import re
import subprocess
import sys
from functools import lru_cache
from pathlib import Path, PurePosixPath


VERSION = re.compile(r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)$")
IMPORT = re.compile(
    r"^[ \t]*(?:\.)?import[ \t]+(qs(?:\.[\w]+)*)(?:[ \t]+[\d.]+)?"
    r"(?:[ \t]+as[ \t]+(\w+))?[ \t]*;?[ \t]*$", re.M)
MEMBER = re.compile(r"\s*(?:\?\.|\.)\s*([A-Za-z_$][\w$]*)")
TYPE_PREFIX = re.compile(r"\b(?:property\s+(?:list\s*<\s*)?|as\s+)$")
OPEN_OBJECT = re.compile(r"\s*\{")
DECLARATION = re.compile(
    r"\b(?:(property)\s+(?:list\s*<[^>]+>|[\w.]+)\s+|(function|signal|enum)\s+)"
    r"([A-Za-z_$][\w$]*)")


def git(root, *args, optional=False):
    result = subprocess.run(["git", "-C", str(root), *args], text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        if optional:
            return None
        raise ValueError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout


def version(text):
    return tuple(map(int, text.split(".")))


def latest_release(shell, tags):
    # This repository inherited upstream tags with higher versions. The fork's
    # current releases embed their exact VERSION at the tagged commit.
    for tag in sorted(tags, key=lambda tag: version(tag[1:]), reverse=True):
        marker = git(shell, "show", f"refs/tags/{tag}:VERSION", optional=True)
        if marker is not None and marker.strip() == tag[1:]:
            return tag
    raise ValueError("cannot identify an Atmosphera release; fetch shell tags")


def resolve_target(shell, tags, newest, pin, floor, *, exact=False):
    tag = "v" + floor
    if tag in tags and version(floor) <= version(newest[1:]):
        print(f"minimum shell {floor}: checking release tag {tag}", file=sys.stderr)
        return Tree(shell, f"refs/tags/{tag}", pin.lexer)
    if version(floor) > version(newest[1:]):
        if exact:
            raise ValueError(f"audit requires release tag {tag}; latest release is {newest}")
        print(f"minimum shell {floor}: {tag} is unreleased (latest {newest}); "
              f"using pinned shell {pin.ref}", file=sys.stderr)
        return pin
    raise ValueError(f"minimum shell {floor}: required historical tag {tag} is missing")


class Tree:
    def __init__(self, shell, ref, lexer):
        self.shell = shell
        self.ref = ref
        self.lexer = lexer
        self.exports = {}
        for name in git(shell, "ls-tree", "-r", "--name-only", "-z", ref).split("\0"):
            path = PurePosixPath(name)
            if path.suffix == ".qml" and path.stem[:1].isupper():
                module = ".".join(("qs", *path.parent.parts))
                self.exports.setdefault(module, {})[path.stem] = name

    @lru_cache(maxsize=None)
    def api(self, module, name):
        path = self.exports.get(module, {}).get(name)
        if not path:
            return False, set()
        source = git(self.shell, "show", f"{self.ref}:{path}")
        _, spans = self.lexer.lex(source)
        masked = blank(source, spans)
        singleton = re.search(r"^[ \t]*pragma[ \t]+Singleton\b", masked, re.M) is not None
        depth = 0
        cursor = 0
        members = set()
        for match in DECLARATION.finditer(masked):
            prefix = masked[cursor:match.start()]
            depth += prefix.count("{") - prefix.count("}")
            cursor = match.start()
            if depth != 1:
                continue
            member = match[3]
            members.add(member)
            if match[1]:
                members.add(member + "Changed")
        return singleton, members


def blank(source, spans):
    chars = list(source)
    for _, start, end in spans:
        chars[start:end] = ["\n" if c == "\n" else " " for c in chars[start:end]]
    return "".join(chars)


def type_reference(code, start, end, qml):
    # A matching identifier alone is not a QML type reference: it can be
    # an object key, a variable, or part of a local declaration.
    if MEMBER.match(code, end):
        return True  # static access (e.g. an enum)
    if not qml:
        return False
    line_start = code.rfind("\n", 0, start) + 1
    return (OPEN_OBJECT.match(code, end) is not None or
            TYPE_PREFIX.search(code, line_start, start) is not None)


def source_findings(path, target, pin, lexer):
    source = path.read_text()
    tokens, spans = lexer.lex(source)
    masked = blank(source, spans)
    bare = {}
    aliases = {}
    missing = set()
    for module, alias in IMPORT.findall(masked):
        if module not in target.exports and module in pin.exports:
            missing.add(module)
            yield f"missing module {module}"
        if alias:
            aliases[alias] = module
        else:
            for name in pin.exports.get(module, {}):
                bare.setdefault(name, set()).add(module)

    # Do not report shell names supplied by private sibling or inline types.
    local = {p.stem for p in path.parent.glob("*.qml")}
    local.update(re.findall(r"\bcomponent\s+([A-Z][\w$]*)\s*:", masked))
    for token in tokens:
        if token.prev_char == "." and not token.spread:
            continue
        name = token.text
        end = token.end
        if name in aliases:
            match = MEMBER.match(masked, end)
            if not match:
                continue
            module, name, end = aliases[name], match[1], match.end()
        else:
            options = bare.get(name, ())
            if name in local or len(options) != 1:
                continue
            module = next(iter(options))
        if module in missing or name not in pin.exports.get(module, {}):
            continue
        if name not in target.exports.get(module, {}):
            if type_reference(masked, token.start, end, path.suffix == ".qml"):
                yield f"missing shell type {module}.{name}"
            continue
        match = MEMBER.match(masked, end)
        if not match:
            continue
        singleton, members = pin.api(module, name)
        # A release comparison checks availability of known shell APIs. On the
        # fallback path the pin is the contract, so an undeclared member is
        # itself a finding; the ordinary linter only checks select singletons.
        if not singleton or (target is not pin and match[1] not in members):
            continue
        old_singleton, old_members = target.api(module, name)
        if not old_singleton or match[1] not in old_members:
            yield f"missing shell API {module}.{name}.{match[1]}"


def check(root, shell, selected=None, against=None):
    expected = (root / ".github/atmosphera-ref").read_text().strip()
    head = git(shell, "rev-parse", "HEAD").strip()
    if expected != head:
        raise ValueError(f"shell HEAD {head} does not match pin {expected}")
    if git(shell, "diff", "HEAD", "--", "Scripts/dev/qml-identifiers.py"):
        raise ValueError("shell lexer does not match the pinned tree")
    sys.path.insert(0, str(shell / "Scripts/dev"))
    lexer = importlib.import_module("qml-identifiers")
    tags = {tag for tag in git(shell, "tag", "--list", "v*").splitlines()
            if VERSION.fullmatch(tag[1:])}
    newest = latest_release(shell, tags)
    pin = Tree(shell, head, lexer)
    targets = {}
    results = {}
    problems = 0
    for file in sorted(root.glob("*/manifest.json")):
        plugin = file.parent.name
        if selected is not None and plugin not in selected:
            continue
        floor = against if against is not None else json.loads(file.read_text()).get("minAtmospheraVersion")
        if floor is None:
            continue
        if not isinstance(floor, str) or not VERSION.fullmatch(floor):
            raise ValueError(f"{plugin}: minAtmospheraVersion must be x.y.z")
        if floor not in targets:
            targets[floor] = resolve_target(shell, tags, newest, pin, floor, exact=against is not None)
        target = targets[floor]
        findings = {}
        for source in sorted(p for p in file.parent.rglob("*") if p.suffix in (".qml", ".js")):
            if source.is_symlink():
                raise ValueError(f"{source}: refusing a symlink source")
            for finding in sorted(set(source_findings(source, target, pin, lexer))):
                findings.setdefault(finding, []).append(source.relative_to(root).as_posix())
        if findings:
            results[plugin] = findings
            problems += len(findings)
    return results, problems


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plugins", type=Path, required=True)
    parser.add_argument("--shell", type=Path, required=True)
    parser.add_argument("--base-ref", help="check plugin directories changed since this Git commit")
    parser.add_argument("--against", help="audit selected plugins against this exact release instead of their manifest floors")
    parser.add_argument("--plugin", action="append", help="restrict to these plugin IDs")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    selected = set(args.plugin) if args.plugin else None
    try:
        if args.base_ref:
            changed = {path.split("/", 1)[0] for path in git(
                args.plugins, "diff", "--name-only", "-z", args.base_ref, "HEAD", "--").split("\0") if "/" in path}
            selected = changed if selected is None else selected & changed
        results, count = check(args.plugins, args.shell, selected, args.against)
        for plugin, findings in results.items():
            for finding, paths in findings.items():
                print(f"{plugin}: {finding} ({paths[0]})")
        if args.report:
            args.report.write_text(json.dumps(results, indent=2) + "\n")
        print(f"minimum shell compatibility: {count} problem(s) in {len(results)} plugin(s)")
        return int(bool(count))
    except (OSError, ValueError) as exc:
        print(f"minimum shell compatibility: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
