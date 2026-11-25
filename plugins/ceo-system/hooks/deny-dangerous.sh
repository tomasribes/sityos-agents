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

# Git global options that may sit between "git" and the subcommand
# (git -C <dir> push, git -c k=v reset, git --git-dir=<dir> clean ...).
# They are stripped so the git rules below see the bare subcommand.
# <arg>: double-quoted, single-quoted or a word without spaces (segments may be glued).
GIT_ARG_RE="(\"[^\"]*\"|'[^']*'|[^[:space:]\"']+)+"
GIT_GLOBAL_RE="git[[:space:]]+(-[Cc][[:space:]]+${GIT_ARG_RE}|--(git-dir|work-tree|namespace)(=|[[:space:]]+)${GIT_ARG_RE}|--no-pager|--paginate|--bare|--no-optional-locks|-p|-P)[[:space:]]+"

is_secret_path() {
  local p="$1"
  printf '%s' "$p" | grep -Eq "$SECRET_OK_RE" && return 1
  printf '%s' "$p" | grep -Eq "$SECRET_RE"
}

case "$tool" in
  Bash)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
    m() { printf '%s' "$cmd" | grep -Eq "$1"; }

    # Strip git global options. Each pass removes one option per git call and every
    # replacement shortens the string, so the loop always ends.
    gitcmd=$cmd
    while :; do
      next=$(printf '%s' "$gitcmd" | sed -E "s/$GIT_GLOBAL_RE/git /g") || deny "no se pudieron normalizar las opciones globales de git"
      [ "$next" = "$gitcmd" ] && break
      gitcmd=$next
    done
    mg() { printf '%s' "$gitcmd" | grep -Eq "$1"; }

    # Git: protected branches, force pushes, destructive resets, merges by agents.
    mg 'git[[:space:]]+push([^|;&]*)[[:space:]:+](master|main)([[:space:]]|$)' && deny "push a master/main"
    mg 'git[[:space:]]+push[^|;&]*(--force|--force-with-lease|[[:space:]]-f([[:space:]]|$)|[[:space:]]\+)' && deny "push forzado"
    mg 'git[[:space:]]+reset[^|;&]*--hard' && deny "git reset --hard"
    mg 'git[[:space:]]+clean[^|;&]*-[a-zA-Z]*f' && deny "git clean -f"
    mg 'git[[:space:]]+branch[^|;&]*-D[[:space:]]+(master|main|develop)' && deny "borrar rama protegida"
    # Closing rule: a git call still starting with an option after normalization carries a
    # global option GIT_GLOBAL_RE does not know, so the rules above cannot see its subcommand.
    # Fail closed if push/reset/clean/branch appears as a word in the same segment.
    mg 'git[[:space:]]+-[^|;&]*[[:space:]](push|reset|clean|branch)([[:space:]]|$)' && deny "opción global de git no reconocida antes de push/reset/clean/branch"
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
