#!/usr/bin/env bash
# Generate the Codex mirror of a repo's Claude Code agents.
#
#   tools/sync-codex-agents.sh [--check] <repo-root>
#
# Source of truth: <repo-root>/.claude/agents/<name>.md (YAML frontmatter + Markdown body).
# Output:          <repo-root>/.codex/agents/<name>.toml with name, description and
#                  developer_instructions (the Markdown body, verbatim).
#
# --check writes nothing: exits 1 if any .toml is missing, differs from its source, or has
# no source left (stale). Without --check it (re)writes every .toml and only reports stale
# ones: deleting a file is the owner's call.
# Compatible with the bash 3.2 shipped with macOS.
set -euo pipefail

usage() { echo "usage: $0 [--check] <repo-root>" >&2; exit 2; }

check=0
if [ "${1:-}" = "--check" ]; then check=1; shift; fi
[ $# -eq 1 ] || usage
root=$1
src_dir="$root/.claude/agents"
out_dir="$root/.codex/agents"
[ -d "$src_dir" ] || { echo "No existe $src_dir" >&2; exit 2; }

tmp=$(mktemp -d)
trap 'rm -r "$tmp"' EXIT

# Value of a single-line frontmatter key, as the YAML parser would read it: plain,
# single-quoted ('' -> ') or double-quoted (\" -> ", \\ -> \).
front_value() {
  local file=$1 key=$2 raw
  raw=$(awk -v k="$key" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 && index($0, k ":") == 1 { sub("^" k ":[ \t]*", ""); print; exit }
  ' "$file")
  case "$raw" in
    \"*\") printf '%s' "$raw" | sed -E 's/^"(.*)"$/\1/' | sed -e 's/\\\\/\x01/g' -e 's/\\"/"/g' -e 's/\x01/\\/g' ;;
    \'*\') printf '%s' "$raw" | sed -E "s/^'(.*)'\$/\\1/" | sed -e "s/''/'/g" ;;
    *) printf '%s' "$raw" ;;
  esac
}

# Markdown body after the closing frontmatter delimiter, without the leading blank line.
body() {
  awk 'c >= 2 { print; next } $0 == "---" { c++ }' "$1" | awk 'NF { started = 1 } started'
}

# TOML basic string escaping for one-line values.
toml_basic() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

render() {
  local md=$1 name desc text
  name=$(front_value "$md" name)
  desc=$(front_value "$md" description)
  [ -n "$name" ] || { echo "Sin 'name' en el frontmatter: $md" >&2; return 1; }
  [ -n "$desc" ] || { echo "Sin 'description' en el frontmatter: $md" >&2; return 1; }
  text=$(body "$md")
  # Multi-line literal strings cannot contain ''' and need no escaping otherwise.
  case "$text" in *"'''"*) echo "El cuerpo contiene ''' y no cabe en un literal TOML: $md" >&2; return 1 ;; esac
  printf '# Generated from .claude/agents/%s by sityos-agents/tools/sync-codex-agents.sh. Do not edit.\n' "$(basename "$md")"
  printf 'name = "%s"\n' "$(toml_basic "$name")"
  printf 'description = "%s"\n' "$(toml_basic "$desc")"
  printf "developer_instructions = '''\n%s\n'''\n" "$text"
}

status=0
found=0
for md in "$src_dir"/*.md; do
  [ -e "$md" ] || continue
  found=1
  name=$(basename "$md" .md)
  render "$md" > "$tmp/$name.toml" || { status=1; continue; }
  if [ $check -eq 1 ]; then
    if [ ! -f "$out_dir/$name.toml" ]; then
      echo "FALTA     .codex/agents/$name.toml"; status=1
    elif ! cmp -s "$tmp/$name.toml" "$out_dir/$name.toml"; then
      echo "DESFASADO .codex/agents/$name.toml"; status=1
    else
      echo "ok        .codex/agents/$name.toml"
    fi
  else
    mkdir -p "$out_dir"
    cp "$tmp/$name.toml" "$out_dir/$name.toml"
    echo "escrito   .codex/agents/$name.toml"
  fi
done
[ $found -eq 1 ] || { echo "No hay agentes en $src_dir" >&2; exit 2; }

for toml in "$out_dir"/*.toml; do
  [ -e "$toml" ] || continue
  name=$(basename "$toml" .toml)
  if [ ! -f "$src_dir/$name.md" ]; then
    echo "HUÉRFANO  .codex/agents/$name.toml (no existe .claude/agents/$name.md)"
    [ $check -eq 1 ] && status=1
  fi
done

exit $status
