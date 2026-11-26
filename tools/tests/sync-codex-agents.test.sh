#!/usr/bin/env bash
# Tests for tools/sync-codex-agents.sh. Run: bash tools/tests/sync-codex-agents.test.sh
# Exit code = number of failed cases.
set -u
SYNC="$(cd "$(dirname "$0")/.." && pwd)/sync-codex-agents.sh"
fails=0
tmp=$(mktemp -d)
trap 'rm -r "$tmp"' EXIT

ok()   { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }
expect() { if eval "$2"; then ok "$1"; else fail "$1"; fi; }

repo="$tmp/repo"
mkdir -p "$repo/.claude/agents"
cat > "$repo/.claude/agents/dev-x.md" <<'EOF'
---
name: dev-x
description: "Dev agent with \"quotes\" and a back\\slash"
tools: Read, Bash
---

Eres el developer.

## Gate
Ejecuta `make test` y revisa "todo".
EOF

bash "$SYNC" "$repo" >/dev/null 2>&1
out="$repo/.codex/agents/dev-x.toml"
expect "writes the toml" '[ -f "$out" ]'
expect "keeps the name" 'grep -qx "name = \"dev-x\"" "$out"'
want_desc='description = "Dev agent with \"quotes\" and a back\\slash"'
expect "reads YAML double quotes and writes TOML escapes" 'grep -qxF "$want_desc" "$out"'
printf -- "---\nname: sq\ndescription: 'It''s plain'\n---\nx\n" > "$repo/.claude/agents/sq.md"
bash "$SYNC" "$repo" >/dev/null 2>&1
expect "reads YAML single quotes" 'grep -qxF "description = \"It'"'"'s plain\"" "$repo/.codex/agents/sq.toml"'
expect "copies the body verbatim" 'grep -qF "Ejecuta \`make test\` y revisa \"todo\"." "$out"'
expect "drops frontmatter-only keys" '! grep -q "^tools" "$out"'
expect "drops the leading blank line of the body" '[ "$(sed -n 5p "$out")" = "Eres el developer." ]'

expect "--check passes when in sync" 'bash "$SYNC" --check "$repo" >/dev/null 2>&1'
printf '\nLínea nueva.\n' >> "$repo/.claude/agents/dev-x.md"
expect "--check fails when the source changed" '! bash "$SYNC" --check "$repo" >/dev/null 2>&1'
bash "$SYNC" "$repo" >/dev/null 2>&1
expect "--check passes after regenerating" 'bash "$SYNC" --check "$repo" >/dev/null 2>&1'

printf 'name = "old"\n' > "$repo/.codex/agents/old.toml"
expect "--check fails on a stale toml" '! bash "$SYNC" --check "$repo" >/dev/null 2>&1'
expect "write mode reports a stale toml without deleting it" 'bash "$SYNC" "$repo" 2>&1 | grep -q "HUÉRFANO" && [ -f "$repo/.codex/agents/old.toml" ]'

bad="$tmp/bad"
mkdir -p "$bad/.claude/agents"
printf -- "---\nname: bad\ndescription: x\n---\nUsa ''' aquí.\n" > "$bad/.claude/agents/bad.md"
expect "rejects a body with triple single quotes" '! bash "$SYNC" "$bad" >/dev/null 2>&1'

nofront="$tmp/nofront"
mkdir -p "$nofront/.claude/agents"
printf 'Sin frontmatter.\n' > "$nofront/.claude/agents/plain.md"
expect "rejects an agent without frontmatter" '! bash "$SYNC" "$nofront" >/dev/null 2>&1'

expect "fails without .claude/agents" '! bash "$SYNC" "$tmp/none" >/dev/null 2>&1'

echo "---- failures: $fails"
exit $fails
