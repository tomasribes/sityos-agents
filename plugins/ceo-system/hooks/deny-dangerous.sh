#!/usr/bin/env bash
# CEO-system guardrail (PreToolUse). Reads the hook JSON on stdin.
# Exit 2 = block the tool call and send the reason back to Claude.
# Fails closed: if the input cannot be parsed, the call is blocked.
set -uo pipefail

deny() {
  printf 'Bloqueado por guardarrail ceo-system: %s. Si es intencionado, pide al dueño que lo ejecute a mano.\n' "$1" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || deny "jq no está instalado; el guardarrail no puede validar la llamada"

input=$(cat) || deny "no se pudo leer la entrada del hook"
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null) || deny "entrada del hook no es JSON válido"

# Secret files: real .env files, private keys, credential/secret stores.
# Allowed: .env.example, .env.dist, .env.sample, .env.template.
SECRET_RE='(^|[/[:space:]"'"'"'=])\.env(\.[A-Za-z0-9_-]+)?([[:space:]"'"'"';|&)]|$)|id_(rsa|ed25519|ecdsa)([^.]|$)|\.pem([[:space:]"'"'"']|$)|(^|[/[:space:]"'"'"'])(credentials|secrets|keys)(/|[[:space:]"'"'"']|$)|\.keystore([[:space:]"'"'"']|$)|keystore\.(json|jks)'
SECRET_OK_RE='\.env\.(example|dist|sample|template)'

is_secret_path() {
  local p="$1"
  printf '%s' "$p" | grep -Eq "$SECRET_OK_RE" && return 1
  printf '%s' "$p" | grep -Eq "$SECRET_RE"
}

case "$tool" in
  Bash)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
    m() { printf '%s' "$cmd" | grep -Eq "$1"; }

    # Git: protected branches, force pushes, destructive resets, merges by agents.
    m 'git[[:space:]]+push([^|;&]*)[[:space:]:+](master|main)([[:space:]]|$)' && deny "push a master/main"
    m 'git[[:space:]]+push[^|;&]*(--force|--force-with-lease|[[:space:]]-f([[:space:]]|$)|[[:space:]]\+)' && deny "push forzado"
    m 'git[[:space:]]+reset[^|;&]*--hard' && deny "git reset --hard"
    m 'git[[:space:]]+clean[^|;&]*-[a-zA-Z]*f' && deny "git clean -f"
    m 'git[[:space:]]+branch[^|;&]*-D[[:space:]]+(master|main|develop)' && deny "borrar rama protegida"
    m 'gh[[:space:]]+pr[[:space:]]+merge' && deny "merge de PR (solo el dueño mergea)"

    # Filesystem.
    m '(^|[;&|[:space:]])rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive[^|;&]*--force|--force[^|;&]*--recursive)' && deny "borrado recursivo forzado (rm -rf)"

    # Databases and containers.
    m 'drush[^|;&]*(sql-drop|sql:drop|sqlc([[:space:]]|$)|sql-cli|sql:cli|[[:space:]"'"'"'=](si|site-install|site:install)([[:space:]"'"'"']|$))' && deny "operación destructiva de BD con drush"
    m '(DROP[[:space:]]+(DATABASE|TABLE|SCHEMA)|TRUNCATE[[:space:]]+TABLE)' && deny "DROP/TRUNCATE SQL"
    m 'docker([[:space:]]+compose|-compose)?[^|;&]*down[^|;&]*(-v|--volumes)' && deny "docker compose down -v (borra volúmenes)"
    m 'docker[[:space:]]+(volume[[:space:]]+(rm|prune)|system[[:space:]]+prune)' && deny "borrado de volúmenes/sistema Docker"

    # Production / infrastructure.
    m '(scripts/)?(deploy|provision-droplet|rollback)\.sh' && deny "script de despliegue o infraestructura de producción"
    m '(^|[;&|[:space:]])doctl[[:space:]]' && deny "doctl (infraestructura DigitalOcean)"

    # Secrets read or exfiltrated through the shell.
    # Strip allowed example files first so "cat .env.example; cat .env" is still caught.
    stripped=$(printf '%s' "$cmd" | sed -E "s/$SECRET_OK_RE/__ok__/g")
    printf '%s' "$stripped" | grep -Eq "$SECRET_RE" && deny "acceso a secretos (.env, claves, credentials, secrets)"
    m '(^|[;&|[:space:]])printenv|(^|[;&|][[:space:]]*)env[[:space:]]*($|[|>;&])' && deny "volcado de variables de entorno"
    ;;

  Read|Edit|Write|MultiEdit|NotebookEdit|Grep|Glob)
    path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // ""')
    if [ -n "$path" ] && is_secret_path "$path"; then
      deny "acceso a fichero de secretos: $path"
    fi
    ;;
esac

exit 0
