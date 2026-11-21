#!/usr/bin/env bash
# install-sityos-agents.sh
# Links SITYOS skills into Claude Code user scope and registers shared MCP servers.
# This repo is the source of truth: everything is symlinked, so edits here apply immediately.
#
# Usage:
#   bash install-sityos-agents.sh                    # skills + MCP
#   bash install-sityos-agents.sh --project <path>   # also install project override
#   bash install-sityos-agents.sh --link-claude-md   # also symlink global/CLAUDE.md -> ~/.claude/CLAUDE.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
AI_PROJECTS="$(cd "$SCRIPT_DIR/.." && pwd)"

PROJECT_PATH=""
LINK_CLAUDE_MD=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_PATH="${2:?--project requires a path}"; shift 2 ;;
    --link-claude-md) LINK_CLAUDE_MD=true; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Symlink $1 -> $2, backing up anything real that is already at $2.
link() {
  local src="$1" dst="$2"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    mv "$dst" "$dst.backup.$(date +%Y%m%d%H%M%S)"
    echo "   ⚠️  backup of existing $dst"
  fi
  ln -sfn "$src" "$dst"
  echo "   ✅ $dst -> $src"
}

echo "🔷 SITYOS Agent Setup"

# ── 1. Skills → ~/.claude/skills (user scope, shared by all projects) ──
echo ""
echo "🤖 Linking skills..."
mkdir -p "$SKILLS_DIR"
for skill_dir in "$SCRIPT_DIR"/agents/*/; do
  [[ -f "$skill_dir/SKILL.md" ]] || continue
  name="$(basename "$skill_dir")"
  link "${skill_dir%/}" "$SKILLS_DIR/$name"
done

# ── 2. MCP servers (user scope) ───────────────────────────────────────
echo ""
echo "🔌 Registering user-scope MCP servers..."
if ! command -v claude >/dev/null 2>&1; then
  echo "   ⚠️  claude CLI not found, skipping MCP"
else
  register_mcp() {
    local name="$1" json="$2"
    if claude mcp get "$name" >/dev/null 2>&1; then
      echo "   ↪︎ $name already registered (claude mcp get $name)"
    else
      claude mcp add-json --scope user "$name" "$json"
      echo "   ✅ $name"
    fi
  }
  # Secrets must come from env vars (${VAR}), never inline.
  register_mcp finanzas-personales \
    "{\"type\":\"stdio\",\"command\":\"npx\",\"args\":[\"tsx\",\"$AI_PROJECTS/finanzas-mcp/src/index.ts\"]}"
fi

# ── 3. Global CLAUDE.md (opt-in) ──────────────────────────────────────
if $LINK_CLAUDE_MD; then
  echo ""
  echo "📄 Linking global CLAUDE.md..."
  link "$SCRIPT_DIR/global/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
fi

# ── 4. Project override (opt-in) ──────────────────────────────────────
if [[ -n "$PROJECT_PATH" ]]; then
  echo ""
  echo "📁 Installing project override in $PROJECT_PATH..."
  [[ -d "$PROJECT_PATH" ]] || { echo "   ❌ directory not found" >&2; exit 1; }
  if [[ -e "$PROJECT_PATH/CLAUDE.md" ]]; then
    echo "   ⚠️  $PROJECT_PATH/CLAUDE.md exists, not overwritten"
  else
    cp "$SCRIPT_DIR/project-override/CLAUDE.md" "$PROJECT_PATH/CLAUDE.md"
  fi
  mkdir -p "$PROJECT_PATH/.claude/commands"
  cp -n "$SCRIPT_DIR/project-override/.claude/commands/"*.md "$PROJECT_PATH/.claude/commands/" || true
  echo "   ✅ done"
fi

echo ""
echo "✅ Done. Verify with: claude mcp list  ·  ls -la ~/.claude/skills"
