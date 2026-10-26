#!/usr/bin/env python3
"""Codex PostToolUse hook: score the files an edit just touched, tell the agent what fired.

Codex sends the hook payload as JSON on stdin. An apply_patch call carries every
file it touched inside one patch, so the paths come from its "*** Add File:",
"*** Update File:" and "*** Move to:" lines. Prose goes through slop-check and code
through code-slop. Findings go back as additionalContext, so the agent fixes them
on its next step. It never blocks an edit: an error is appended to hook-errors.log
next to the checks, and the hook exits 0 so Codex carries on.
"""

import json
import pathlib
import subprocess
import sys

BIN = pathlib.Path.home() / ".local" / "share" / "usc-codex-setup" / "bin"
PROSE = {".md", ".mdx", ".txt"}
CODE = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".py", ".sh", ".go", ".rs"}
PREFIXES = ("*** Add File: ", "*** Update File: ", "*** Move to: ")


def touched(payload):
    cwd = pathlib.Path(payload.get("cwd") or ".")
    tool_input = payload.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        return []
    paths = []
    if isinstance(tool_input.get("file_path"), str):
        paths.append(tool_input["file_path"])
    patch = tool_input.get("command") or tool_input.get("input") or ""
    if isinstance(patch, list):
        patch = "\n".join(str(p) for p in patch)
    for line in str(patch).splitlines():
        for prefix in PREFIXES:
            if line.startswith(prefix):
                paths.append(line[len(prefix):].strip())
    out = []
    for p in paths:
        full = (cwd / p).resolve()
        if full.is_file() and "node_modules" not in full.parts and full not in out:
            out.append(full)
    return out


def score(tool, path):
    result = subprocess.run(
        [sys.executable, str(BIN / tool), str(path), "--json"],
        capture_output=True, text=True, timeout=20,
    )
    data = json.loads(result.stdout or "null")
    if isinstance(data, list):
        data = data[0] if data else {}
    return data or {}


def main():
    payload = json.load(sys.stdin)
    notes = []
    for path in touched(payload):
        tool = "slop-check" if path.suffix in PROSE else "code-slop" if path.suffix in CODE else None
        if not tool:
            continue
        data = score(tool, path)
        limit = 19 if tool == "slop-check" else 40
        if data.get("score", 0) > limit:
            hits = data.get("findings", [])[:8]
            lines = [f"  L{h.get('line')} {h.get('rule')}: {h.get('text', '')[:70]}" for h in hits]
            notes.append(f"{tool} scored {path.name} at {data['score']} (limit {limit}):\n" + "\n".join(lines))
    if notes:
        text = "Slop check on the files you just edited. Fix these before moving on:\n" + "\n\n".join(notes)
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": text}}))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        try:
            with open(BIN.parent / "hook-errors.log", "a") as log:
                log.write(f"{type(error).__name__}: {error}\n")
        except OSError:
            print(f"slop hook failed: {error}", file=sys.stderr)
    sys.exit(0)
