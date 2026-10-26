#!/bin/bash
# Installs the shared Codex CLI setup on a Mac (Linux works too), merged into an existing ~/.codex.
#
#   ./install.sh              install everything this script knows about
#   ./install.sh --dry-run    print what would happen, change nothing
#   ./install.sh --help       flags
#
# Safe to run more than once. It never overwrites a file of yours: a skill or MCP
# server whose name already exists is skipped and listed at the end. AGENTS.md
# gets one marked block, hooks.json gets one hook, config.toml gets one flag,
# all after a backup. Tools land in ~/.local/bin with no sudo.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
SKILLS_DIR="$HOME/.agents/skills"
SETUP_DIR="$HOME/.local/share/usc-codex-setup"
VENDOR="$SETUP_DIR/vendor"
LOCAL_BIN="$HOME/.local/bin"
BACKUP_DIR="$SETUP_DIR/backups/$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0; DO_PREREQS=1; DO_SKILLS=1; DO_MCP=1; DO_CONFIG=1; DO_LIFE=1
LIFE_DIR="${LIFE_DIR:-$HOME/life}"

usage() {
  cat <<'USAGE'
Usage: ./install.sh [flags]

  --dry-run        Print every action, change nothing.
  --no-prereqs     Skip node, codex, gh, jq, ripgrep, uv.
  --no-skills      Skip skills.
  --no-mcp         Skip MCP servers.
  --no-config      Skip AGENTS.md, hooks, check tools.
  --no-life        Skip the ~/life folder.

Environment:
  CODEX_HOME                     Codex home, default ~/.codex
  LIFE_DIR                       your life folder, default ~/life
  GITHUB_PERSONAL_ACCESS_TOKEN   used for the GitHub MCP server when gh isn't signed in
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --no-prereqs) DO_PREREQS=0 ;;
    --no-skills) DO_SKILLS=0 ;;
    --no-mcp) DO_MCP=0 ;;
    --no-config) DO_CONFIG=0 ;;
    --no-life) DO_LIFE=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown flag: $1"; usage; exit 2 ;;
  esac
  shift
done

bold() { printf "\n\033[1m%s\033[0m\n" "$*"; }
ok()   { printf "  \033[32m+\033[0m %s\n" "$*"; INSTALLED+=("$*"); }
have() { printf "  \033[90m= %s\033[0m\n" "$*"; SKIPPED+=("$*"); }
warn() { printf "  \033[33m!\033[0m %s\n" "$*"; PROBLEMS+=("$*"); }
todo() { NEEDS+=("$*"); }
run()  { if [ "$DRY_RUN" = 1 ]; then printf "  \033[90m[dry-run] %s\033[0m\n" "$*"; return 0; fi; "$@"; }

INSTALLED=(); SKIPPED=(); PROBLEMS=(); NEEDS=()

OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS" in
  Linux) ;;
  Darwin) ;;
  *) echo "Unsupported OS: $OS"; exit 1 ;;
esac
command -v python3 >/dev/null 2>&1 || { echo "python3 is required (sudo apt install python3)"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl is required (sudo apt install curl)"; exit 1; }

export PATH="$LOCAL_BIN:$PATH"

# latest_asset <owner/repo> <regex>: download URL of the newest release asset that
# matches. The URL is printed by python from the API's JSON and used only as a curl
# argument, never pasted into a shell string.
latest_asset() { curl -fsSL "https://api.github.com/repos/$1/releases/latest" | python3 -I -c 'import json,re,sys
for a in json.load(sys.stdin)["assets"]:
    if re.search(sys.argv[1], a["name"]): print(a["browser_download_url"]); break' "$2"; }

# ── 1. Prerequisites, official release binaries into ~/.local, no sudo ──────
if [ "$DO_PREREQS" = 1 ]; then
  bold "1. Prerequisites"
  run mkdir -p "$LOCAL_BIN"
  if command -v git >/dev/null 2>&1; then have "git"; else warn "BLOCKED: git missing, run: sudo apt install -y git"; fi
  nodearch=x64 gharch=amd64 rgtriple=x86_64-unknown-linux-musl jqarch=amd64 nodeos=linux ghos=linux jqos=linux
  case "$ARCH" in aarch64|arm64) nodearch=arm64 gharch=arm64 rgtriple=aarch64-unknown-linux-gnu jqarch=arm64 ;; esac
  [ "$OS" = Darwin ] && { nodeos=darwin ghos=macOS jqos=macos; rgtriple="${ARCH/arm64/aarch64}-apple-darwin"; }
  t="$(mktemp -d)"
  if command -v node >/dev/null 2>&1 && [ "$(node -p 'process.versions.node.split(".")[0]')" -ge 20 ] 2>/dev/null; then have "node $(node --version)"
  elif [ "$DRY_RUN" = 1 ]; then run "install node 22 into ~/.local/node"; else
    f="$(curl -fsSL https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt | awk '{print $2}' | grep -E "^node-v[0-9.]+-$nodeos-$nodearch\.tar\.gz$" | head -1)"
    if [ -n "$f" ] && curl -fsSL "https://nodejs.org/dist/latest-v22.x/$f" | tar xz -C "$t"; then
      rm -rf "$HOME/.local/node" && mv "$t/${f%.tar.gz}" "$HOME/.local/node" \
        && for b in node npm npx; do ln -sf "$HOME/.local/node/bin/$b" "$LOCAL_BIN/$b"; done && ok "node 22" || warn "node install failed"
    else warn "node download failed"; fi
  fi
  if command -v codex >/dev/null 2>&1; then have "codex $(codex --version 2>/dev/null | head -1)"
  elif [ "$DRY_RUN" = 1 ]; then run "npm install @openai/codex into ~/.local/codex"; else
    npm install --silent --prefix "$HOME/.local/codex" @openai/codex >/dev/null 2>&1 \
      && ln -sf "$HOME/.local/codex/node_modules/.bin/codex" "$LOCAL_BIN/codex" && ok "codex CLI" \
      || warn "codex install failed (npm install -g @openai/codex)"
  fi
  if command -v gh >/dev/null 2>&1; then have "gh"; elif [ "$DRY_RUN" = 1 ]; then run "install gh"; else
    if [ "$OS" = Linux ]; then
      curl -fsSL "$(latest_asset cli/cli "linux_${gharch}\\.tar\\.gz$")" | tar xz -C "$t" && cp "$t"/gh_*/bin/gh "$LOCAL_BIN/gh" && ok "gh" || warn "gh download failed"
    else
      curl -fsSL -o "$t/gh.zip" "$(latest_asset cli/cli "macOS_${gharch}\\.zip$")" && (cd "$t" && unzip -q gh.zip) && cp "$t"/gh_*/bin/gh "$LOCAL_BIN/gh" && ok "gh" || warn "gh download failed"
    fi
  fi
  if command -v jq >/dev/null 2>&1; then have "jq"; elif [ "$DRY_RUN" = 1 ]; then run "install jq"; else
    curl -fsSL -o "$LOCAL_BIN/jq" "https://github.com/jqlang/jq/releases/latest/download/jq-$jqos-$jqarch" && chmod +x "$LOCAL_BIN/jq" && ok "jq" || warn "jq download failed"
  fi
  if command -v rg >/dev/null 2>&1; then have "ripgrep"; elif [ "$DRY_RUN" = 1 ]; then run "install ripgrep"; else
    curl -fsSL "$(latest_asset BurntSushi/ripgrep "${rgtriple}\\.tar\\.gz$")" | tar xz -C "$t" && cp "$t"/ripgrep-*/rg "$LOCAL_BIN/rg" && ok "ripgrep" || warn "ripgrep download failed"
  fi
  if command -v uv >/dev/null 2>&1; then have "uv"; else
    run sh -c 'curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh' >/dev/null 2>&1 && ok "uv" || warn "uv install failed"
  fi
  rm -rf "$t"
  # New shells need ~/.local/bin on PATH too.
  for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    { [ -f "$rc" ] || [ "$rc" = "$HOME/.bashrc" ]; } || continue
    grep -qs '.local/bin' "$rc" && continue
    if [ "$DRY_RUN" = 1 ]; then run "add ~/.local/bin to PATH in $rc"
    else printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >>"$rc" && ok "PATH line in $(basename "$rc")"; fi
  done
  if gh auth status >/dev/null 2>&1; then have "gh signed in"
  elif [ "$DRY_RUN" = 0 ] && [ -t 0 ] && command -v gh >/dev/null 2>&1; then
    echo "  GitHub sign-in: copy the code below, then press Enter to open the browser"
    gh auth login --web -h github.com -p https && ok "gh signed in" || warn "gh sign-in didn't finish: gh auth login --web"
  else todo "GitHub: gh auth login --web"; fi
  if [ "$DRY_RUN" = 0 ] && command -v codex >/dev/null 2>&1 && [ ! -f "$CODEX_DIR/auth.json" ]; then
    todo "Codex: run codex once and sign in with ChatGPT (or set OPENAI_API_KEY)"
  fi
fi

if [ "$DRY_RUN" = 0 ]; then
  mkdir -p "$SKILLS_DIR" "$VENDOR" "$BACKUP_DIR" "$CODEX_DIR"
  for f in AGENTS.md hooks.json config.toml; do
    [ -f "$CODEX_DIR/$f" ] && cp -p "$CODEX_DIR/$f" "$BACKUP_DIR/" 2>/dev/null
  done
fi

# ── 2. Skills, symlinked into ~/.agents/skills where Codex reads them ───────
# Download one repo as a tarball. codeload's HEAD needs no branch name, and the repo
# path is checked against a strict pattern, so nothing from the network reaches a shell
# string. A second run refreshes the copy. An optional third argument pins a commit.
fetch_repo() {
  local name="$1" repo="$2" ref="${3:-HEAD}" dir="$VENDOR/$1"
  case "$repo" in *[!A-Za-z0-9._/-]*) warn "bad repo $repo"; return 1 ;; esac
  case "$ref" in HEAD) ;; *[!0-9a-f]*) warn "bad ref $ref"; return 1 ;; esac
  if [ "$DRY_RUN" = 1 ]; then run "download github.com/$repo into $dir"; return 0; fi
  local t; t="$(mktemp -d)"
  if curl -fsSL "https://codeload.github.com/$repo/tar.gz/$ref" | tar xz -C "$t" --strip-components 1; then
    rm -rf "$dir" && mv "$t" "$dir"; return 0
  fi
  rm -rf "$t"
  [ -d "$dir" ] && { warn "could not refresh $repo, kept the old copy"; return 0; }
  warn "could not download $repo"; return 1
}

# Symlink one skill folder into ~/.agents/skills unless that name is taken by
# something that isn't ours.
link_skill() {
  local src="$1" name="${2:-$(basename "$1")}" dst="$SKILLS_DIR/${2:-$(basename "$1")}"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then have "skill $name"; return; fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then have "skill $name (you already have one)"; return; fi
  if [ "$DRY_RUN" = 0 ] && [ ! -f "$src/SKILL.md" ]; then warn "skill $name: no SKILL.md at $src"; return; fi
  run ln -s "$src" "$dst" && ok "skill $name"
}

ANTHROPIC_SKILLS=(pdf docx xlsx webapp-testing mcp-builder skill-creator)

if [ "$DO_SKILLS" = 1 ]; then
  bold "2. Skills"
  run mkdir -p "$SETUP_DIR/skills"
  # This repo's own skills are copied first, so the links survive deleting the download.
  [ "$DRY_RUN" = 0 ] && cp -R "$HERE"/skills/. "$SETUP_DIR/skills/"
  for d in "$HERE"/skills/*/; do n="$(basename "$d")"; link_skill "$SETUP_DIR/skills/$n" "$n"; done
  fetch_repo no-ai-slop petergyang/no-ai-slop && link_skill "$VENDOR/no-ai-slop/skills/no-ai-slop" no-ai-slop
  # ai-scan require()s this repo's detector, so it runs as code: pinned, never HEAD.
  fetch_repo avoid-ai-writing conorbronsdon/avoid-ai-writing 209815cdeb4af942616daec89a5e0a706c804e3a && link_skill "$VENDOR/avoid-ai-writing" avoid-ai-writing
  fetch_repo carlton-skills 31Carlton7/skills && link_skill "$VENDOR/carlton-skills/deslop" deslop
  fetch_repo humanizer blader/humanizer && link_skill "$VENDOR/humanizer" humanizer
  fetch_repo anthropic-skills anthropics/skills \
    && for s in "${ANTHROPIC_SKILLS[@]}"; do link_skill "$VENDOR/anthropic-skills/skills/$s" "$s"; done
fi

# ── 3. MCP servers, registered with absolute commands ───────────────────────
# A server launched from a desktop app or IDE gets a PATH with no ~/.local/bin, and a
# bare `npx` then dies with "connection closed" (seen on a Homebrew-less Mac,
# 2026-10-23). So every command is stored as an absolute path, with a PATH that finds node.
MCP_PATH="$LOCAL_BIN:$HOME/.local/node/bin:/usr/local/bin:/usr/bin:/bin"
mcp_has() { [ -f "$CODEX_DIR/config.toml" ] && grep -qE "^\[mcp_servers\.\"?$1\"?\]" "$CODEX_DIR/config.toml"; }
mcp_add() {
  local name="$1" cmd="$2"; shift 2
  if mcp_has "$name"; then have "mcp $name"; return; fi
  case "$cmd" in /*) ;; *) cmd="$(command -v "$cmd" || true)" ;; esac
  if [ -z "$cmd" ] && [ "$DRY_RUN" = 0 ]; then warn "mcp $name skipped: its command isn't installed"; return; fi
  run codex mcp add "$name" --env "PATH=$MCP_PATH" -- "${cmd:-<cmd>}" "$@" >/dev/null 2>&1 && ok "mcp $name" || warn "mcp $name failed to add"
}

if [ "$DO_MCP" = 1 ]; then
  bold "3. MCP servers"
  if ! command -v codex >/dev/null 2>&1 && [ "$DRY_RUN" = 0 ]; then
    warn "no codex CLI, MCP servers skipped this run"
  else
    mcp_add context7 npx -y @upstash/context7-mcp
    mcp_add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking
    mcp_add playwright npx -y @playwright/mcp@latest --headless
    mcp_add chrome-devtools npx -y chrome-devtools-mcp@latest --headless
    mcp_add fetch uvx mcp-server-fetch
    mcp_add git uvx mcp-server-git
    # GitHub: the server asks gh for the token each time it starts, so no token is
    # ever written to config.toml. The two paths are resolved here and quoted, never
    # read from the network.
    if mcp_has github; then have "mcp github"
    elif [ "$DRY_RUN" = 1 ] || gh auth status >/dev/null 2>&1; then
      GH_BIN="$(command -v gh || echo gh)"; NPX_BIN="$(command -v npx || echo npx)"
      mcp_add github /bin/sh -c "GITHUB_PERSONAL_ACCESS_TOKEN=\$('$GH_BIN' auth token) exec '$NPX_BIN' -y @modelcontextprotocol/server-github"
    else
      todo "GitHub MCP: sign in with gh auth login --web, then ./install.sh --no-prereqs --no-skills --no-config"
    fi
  fi
fi

# ── 4. Check tools, AGENTS.md, hooks ────────────────────────────────────────
if [ "$DO_CONFIG" = 1 ]; then
  bold "4. Checks, AGENTS.md, hooks"
  run mkdir -p "$SETUP_DIR/bin" "$SETUP_DIR/hooks" "$LOCAL_BIN"
  if [ "$DRY_RUN" = 0 ]; then
    for f in "$HERE"/bin/* "$HERE"/codex/hooks/*; do [ -f "$f" ] || continue
      case "$f" in */codex/hooks/*) cp "$f" "$SETUP_DIR/hooks/" ;; *) cp "$f" "$SETUP_DIR/bin/" ;; esac; done
    chmod +x "$SETUP_DIR"/bin/*
  fi
  for f in "$HERE"/bin/*; do
    [ -f "$f" ] || continue
    n="$(basename "$f")" dst="$LOCAL_BIN/$(basename "$f")"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$SETUP_DIR/bin/$n" ]; then have "$n"
    elif [ -e "$dst" ] || [ -L "$dst" ]; then have "$n (you already have one, left alone)"
    else run ln -s "$SETUP_DIR/bin/$n" "$dst" && ok "$n"; fi
  done
  dry=""; [ "$DRY_RUN" = 1 ] && dry="--dry-run"
  python3 -I "$HERE/lib/merge_codex.py" agents "$CODEX_DIR/AGENTS.md" "$HERE/codex/AGENTS-block.md" $dry | sed 's/^/  /'
  python3 -I "$HERE/lib/merge_codex.py" hooks "$CODEX_DIR/hooks.json" "$SETUP_DIR/hooks/slop-after-edit.py" $dry | sed 's/^/  /'
  python3 -I "$HERE/lib/merge_codex.py" flag "$CODEX_DIR/config.toml" $dry | sed 's/^/  /'
  todo "Codex hooks: on the next codex launch, review and trust the new slop hook when Codex asks. Until then it doesn't run, and the pre-commit hook still does"
  todo "In each repo you commit to: run agent-hook-init (or the repo's own core.hooksPath setup)"
fi

# ── 5. Your life folder ─────────────────────────────────────────────────────
# Files you already have are never touched, so re-running only fills in what's missing.
if [ "$DO_LIFE" = 1 ]; then
  bold "5. Your life folder ($LIFE_DIR)"
  run mkdir -p "$LIFE_DIR"
  for f in "$HERE"/life-template/*; do
    n="$(basename "$f")"
    if [ -e "$LIFE_DIR/$n" ]; then have "life/$n"; else run cp "$f" "$LIFE_DIR/$n" && ok "life/$n"; fi
  done
  if [ ! -d "$LIFE_DIR/.git" ] && command -v git >/dev/null 2>&1; then
    run git -C "$LIFE_DIR" init -q && ok "life folder tracked with git, so every change can be undone"
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────────────
bold "Done"
echo "  installed: ${#INSTALLED[@]}   already had: ${#SKIPPED[@]}   problems: ${#PROBLEMS[@]}"
[ "$DRY_RUN" = 0 ] && echo "  backups: $BACKUP_DIR"
if [ ${#PROBLEMS[@]} -gt 0 ]; then bold "Problems"; for p in "${PROBLEMS[@]}"; do echo "  - $p"; done; fi
if [ ${#NEEDS[@]} -gt 0 ]; then bold "Still needs you"; for n in "${NEEDS[@]}"; do echo "  - $n"; done; fi
echo
echo "Open a new Terminal window, then type:  cd ~/life && codex"
echo "and say: set me up"
