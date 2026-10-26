#!/usr/bin/env python3
"""Merge this setup into an existing Codex home without replacing anything of yours.

    merge_codex.py hooks  <hooks.json> <hook-script> [--dry-run]
    merge_codex.py agents <AGENTS.md>  <block-file>  [--dry-run]
    merge_codex.py flag   <config.toml>              [--dry-run]

hooks:  adds one PostToolUse entry that runs the hook script, unless a hook with
        that command is already there. Other hooks are untouched.
agents: writes the block between two marker comments. A second run replaces only
        what sits between the markers, so your own text above and below stays.
flag:   turns on [features] hooks = true, unless you set it to false yourself.
Each prints one line saying what it did.
"""

import json
import pathlib
import re
import sys

START = "<!-- usc-codex-setup:start (re-running install.sh rewrites this block) -->"
END = "<!-- usc-codex-setup:end -->"


def write(path, text, dry):
    if dry:
        print(f"[dry-run] would write {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def hooks(path, script, dry):
    data = json.loads(path.read_text()) if path.exists() and path.read_text().strip() else {}
    command = f"python3 {script}"
    entries = data.setdefault("hooks", {}).setdefault("PostToolUse", [])
    for group in entries:
        for h in group.get("hooks", []):
            if "slop-after-edit.py" in str(h.get("command", "")):
                print("= hooks.json already runs the slop hook")
                return
    entries.append({
        "matcher": "apply_patch|Edit|Write",
        "hooks": [{"type": "command", "command": command, "timeout": 30,
                   "statusMessage": "Slop check on edited files"}],
    })
    write(path, json.dumps(data, indent=2) + "\n", dry)
    print("+ hooks.json: PostToolUse slop hook added")


def agents(path, block_file, dry):
    block = f"{START}\n{pathlib.Path(block_file).read_text().strip()}\n{END}\n"
    text = path.read_text() if path.exists() else ""
    if START in text and END in text:
        before, rest = text.split(START, 1)
        after = rest.split(END, 1)[1].lstrip("\n")
        new = before + block + after
        if new == text:
            print("= AGENTS.md block already current")
            return
        write(path, new, dry)
        print("+ AGENTS.md: setup block refreshed, your text untouched")
        return
    new = (text.rstrip("\n") + "\n\n" if text.strip() else "") + block
    write(path, new, dry)
    print("+ AGENTS.md: setup block appended, your text untouched" if text.strip() else "+ AGENTS.md created")


def flag(path, dry):
    text = path.read_text() if path.exists() else ""
    m = re.search(r"(?ms)^\[features\]\s*$(.*?)(?=^\[|\Z)", text)
    if m and re.search(r"(?m)^\s*hooks\s*=\s*true", m.group(1)):
        print("= config.toml already has hooks = true")
        return
    if m and re.search(r"(?m)^\s*hooks\s*=", m.group(1)):
        print("! config.toml sets hooks to something other than true, left alone")
        return
    if m:
        new = text[:m.end(0) - len(m.group(1))] + "hooks = true\n" + m.group(1) + text[m.end(0):]
    else:
        new = (text.rstrip("\n") + "\n\n" if text.strip() else "") + "[features]\nhooks = true\n"
    write(path, new, dry)
    print("+ config.toml: [features] hooks = true")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--dry-run"]
    dry = "--dry-run" in sys.argv
    kind = args[0]
    if kind == "hooks":
        hooks(pathlib.Path(args[1]), args[2], dry)
    elif kind == "agents":
        agents(pathlib.Path(args[1]), args[2], dry)
    elif kind == "flag":
        flag(pathlib.Path(args[1]), dry)
    else:
        sys.exit(f"unknown kind {kind}")
