#!/bin/bash
# Run the installer in an empty HOME: a dry run must write nothing, a real run (skills
# and config, no downloads of tools, no MCP) must install, and a second real run must
# add nothing. Then the checks themselves get one pass and one fail case each.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

bash -n "$HERE/install.sh"
for f in "$HERE"/bin/agent-check "$HERE"/bin/agent-hook-init; do bash -n "$f"; done
PYTHONPYCACHEPREFIX="$T/pyc" python3 -m py_compile "$HERE/bin/slop-check" "$HERE/bin/code-slop" "$HERE/lib/merge_codex.py" "$HERE/codex/hooks/slop-after-edit.py"
for d in "$HERE"/skills/*/; do [ -f "$d/SKILL.md" ] || fail "missing SKILL.md in $d"; done

# 1. Dry run writes nothing.
mkdir "$T/dry"
HOME="$T/dry" CODEX_HOME="$T/dry/.codex" bash "$HERE/install.sh" --dry-run --no-prereqs >"$T/dry.txt" 2>&1 || { cat "$T/dry.txt"; fail "dry run exited nonzero"; }
# Rosetta writes ~/.cache/rosetta when an amd64 container runs on an Apple Silicon Mac
# (seen 2026-10-24 testing this in Docker), so that one folder isn't the installer's.
rm -rf "$T/dry/.cache/rosetta"; rmdir "$T/dry/.cache" 2>/dev/null || true
[ -z "$(ls -A "$T/dry")" ] || { ls -A "$T/dry"; fail "dry run wrote files"; }

# 2. Real run into an empty HOME.
mkdir "$T/home"
run() { HOME="$T/home" CODEX_HOME="$T/home/.codex" PATH="$T/home/.local/bin:/usr/bin:/bin:$(dirname "$(command -v python3)"):$(dirname "$(command -v node)")" \
  bash "$HERE/install.sh" --no-prereqs --no-mcp >"$1" 2>&1; }
run "$T/first.txt" || { cat "$T/first.txt"; fail "first run exited nonzero"; }
H="$T/home"
for s in debugging reviewing-changes shipping interface repo-health deep-research life-ops no-ai-slop avoid-ai-writing deslop humanizer; do
  [ -f "$H/.agents/skills/$s/SKILL.md" ] || { cat "$T/first.txt"; fail "skill $s not installed"; }
done
for b in agent-check slop-check code-slop ai-scan agent-hook-init; do [ -x "$H/.local/bin/$b" ] || fail "$b not on PATH"; done
[ ! -e "$H/.local/bin/__pycache__" ] || fail "a cache folder was linked as a command"
grep -q "usc-codex-setup:start" "$H/.codex/AGENTS.md" || fail "AGENTS.md block missing"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert any("slop-after-edit" in h["command"] for g in d["hooks"]["PostToolUse"] for h in g["hooks"])' "$H/.codex/hooks.json" || fail "hook missing"
grep -q "^hooks = true" "$H/.codex/config.toml" || fail "hooks flag missing"
for f in AGENTS.md ME.md NOW.md PEOPLE.md LOOPS.md; do [ -f "$H/life/$f" ] || fail "life/$f missing"; done

# 3. Second run adds nothing, and the user's own AGENTS.md text survives.
printf '\nMy own rule.\n' >>"$H/.codex/AGENTS.md"
printf -- '- Name: Maya\n' >"$H/life/ME.md"
run "$T/second.txt" || { cat "$T/second.txt"; fail "second run exited nonzero"; }
grep -q "Name: Maya" "$H/life/ME.md" || fail "second run overwrote life/ME.md"
grep -q "installed: 0 " "$T/second.txt" || { cat "$T/second.txt"; fail "second run installed something"; }
grep -q "My own rule." "$H/.codex/AGENTS.md" || fail "second run dropped the user's AGENTS.md text"
[ "$(grep -c "usc-codex-setup:start" "$H/.codex/AGENTS.md")" = 1 ] || fail "AGENTS.md block duplicated"

# 4. The checks catch slop and pass clean work.
printf 'Our robust platform \xe2\x80\x94 seamless.\n' >"$T/bad.md"
printf 'Maya fixed the login bug on Tuesday.\n' >"$T/good.md"
! HOME="$H" "$H/.local/bin/slop-check" "$T/bad.md" --max 19 >/dev/null || fail "slop-check passed slop"
HOME="$H" "$H/.local/bin/slop-check" "$T/good.md" --max 19 >/dev/null || fail "slop-check failed clean prose"
HOME="$H" "$H/.local/bin/ai-scan" "$T/good.md" >/dev/null || fail "ai-scan could not find its detector"
R="$T/repo"; mkdir "$R"; git -C "$R" init -q
printf '# Notes\n\nOur robust platform \xe2\x80\x94 seamless.\n' >"$R/notes.md"
git -C "$R" add notes.md
! (cd "$R" && "$H/.local/bin/agent-check" >/dev/null) || fail "agent-check passed a slop commit"
printf '# Notes\n\nThe bridge retries a failed send twice.\n' >"$R/notes.md"; git -C "$R" add notes.md
(cd "$R" && "$H/.local/bin/agent-check" >/dev/null) || fail "agent-check failed a clean commit"
(cd "$R" && "$H/.local/bin/agent-hook-init" >/dev/null) && [ -x "$R/.git/hooks/pre-commit" ] || fail "agent-hook-init added no hook"

# 5. The Codex hook reads an apply_patch payload and reports slop.
printf 'Our robust platform \xe2\x80\x94 seamless.\n' >"$R/notes.md"
OUT="$(printf '{"cwd":"%s","tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\\n*** Update File: notes.md\\n*** End Patch"}}' "$R" \
  | HOME="$H" python3 "$H/.local/share/usc-codex-setup/hooks/slop-after-edit.py")"
grep -q additionalContext <<<"$OUT" || fail "codex hook stayed silent on slop"

# 6. Nothing personal or dashed ships.
if grep -rIl -i "joelnewton\|zeutara\|amber circles\|togari" "$HERE" --exclude-dir=.git --exclude=smoke.sh; then fail "personal text left"; fi
python3 -I - "$HERE" <<'PY' || fail "em or en dash in a file"
import pathlib, sys
bad = [str(p) for p in pathlib.Path(sys.argv[1]).rglob("*")
       if p.is_file() and ".git" not in p.parts
       and ("\u2014" in p.read_text(errors="ignore") or "\u2013" in p.read_text(errors="ignore"))]
print("\n".join(bad))
sys.exit(1 if bad else 0)
PY
echo "smoke ok"
