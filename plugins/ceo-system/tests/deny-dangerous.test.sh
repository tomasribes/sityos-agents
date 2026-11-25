#!/usr/bin/env bash
# Test matrix for hooks/deny-dangerous.sh. Run: bash tests/deny-dangerous.test.sh
# Exit code = number of failed cases.
set -u
HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/deny-dangerous.sh"
fails=0

t() {
  local exp="$1" tool="$2" key="$3" val="$4" json rc got
  json=$(jq -nc --arg t "$tool" --arg k "$key" --arg v "$val" '{tool_name:$t, tool_input:{($k):$v}}')
  printf '%s' "$json" | "$HOOK" >/dev/null 2>&1; rc=$?
  if [ $rc -eq 2 ]; then got=DENY; else got=ok; fi
  if [ "$got" = "$exp" ]; then
    printf 'PASS %-4s %-5s %s\n' "$exp" "$tool" "$val"
  else
    printf 'FAIL %-4s %-5s %s (got %s)\n' "$exp" "$tool" "$val" "$got"; fails=$((fails + 1))
  fi
}

B=Bash; c=command
# git
t DENY $B $c 'git push origin master'
t DENY $B $c 'git push origin HEAD:main'
t DENY $B $c 'git push --force origin feature'
t DENY $B $c 'git push -f'
t ok   $B $c 'git push -u origin sito/dev-12-defer-css'
t ok   $B $c 'git push origin develop'
t DENY $B $c 'git reset --hard HEAD~1'
t DENY $B $c 'gh pr merge 12 --squash'
t ok   $B $c 'gh pr create --base develop --title "DEV-12: x"'
# git with global options (-C, -c, --git-dir, --no-pager) before the subcommand
t DENY $B $c 'git -C /repo push origin master'
t DENY $B $c 'git -C "/tmp/a b" push --force origin x'
t DENY $B $c 'git -c user.name=x push origin HEAD:main'
t DENY $B $c 'git --git-dir=/repo/.git reset --hard'
t DENY $B $c 'git -C /repo clean -fd'
t DENY $B $c 'git --no-pager -C /repo branch -D develop'
t ok   $B $c 'git -C .claude/worktrees/ceo-log push origin ceo-log'
t ok   $B $c 'git -C /repo log --oneline -5'
t ok   $B $c 'git -C /repo commit -m "x" -- .ceo/ceo-log.md'
# git with a global option the hook does not normalize (closing rule)
t DENY $B $c 'git --literal-pathspecs push origin master'
t DENY $B $c 'git --exec-path=/usr/lib/git-core push --force origin x'
t DENY $B $c 'git --config-env=core.pager=PAGER reset --hard'
t DENY $B $c 'git --no-replace-objects clean -fd'
t DENY $B $c 'git --literal-pathspecs push origin feature'
t ok   $B $c 'git --version'
t ok   $B $c 'git --literal-pathspecs log --oneline -5'
# filesystem
t DENY $B $c 'rm -rf build/'
t DENY $B $c 'rm -fr node_modules'
t ok   $B $c 'rm -f tmp.txt'
# database / containers
t DENY $B $c 'make drush c="sql-drop -y"'
t DENY $B $c 'make drush c="si -y"'
t DENY $B $c 'drush site:install standard'
t ok   $B $c 'make drush c="cex -y"'
t ok   $B $c 'make drush c="cr"'
t DENY $B $c 'docker compose down -v'
t ok   $B $c 'docker compose down'
# production
t DENY $B $c './scripts/deploy.sh --ci-deploy --droplet 1.2.3.4'
t ok   $B $c './scripts/build-artifact.sh'
t DENY $B $c 'doctl compute droplet list'
# secrets via shell
t DENY $B $c 'cat .env'
t DENY $B $c 'cat .env.example; cat .env'
t DENY $B $c 'node --env-file=.env x.js'
t ok   $B $c 'cp .env.example .env.example.bak'
t ok   $B $c 'cat .env.example'
t ok   $B $c 'grep -r "process.env.API" src/'
t DENY $B $c 'cat ~/.ssh/id_rsa'
t DENY $B $c 'ls secrets/'
t DENY $B $c 'cat credentials/token.json'
t ok   $B $c 'python scripts/generate_keystore.py --help'
t DENY $B $c 'printenv'
t DENY $B $c 'env | grep KEY'
t ok   $B $c 'env NODE_ENV=test npm test'
t ok   $B $c 'make test'
# file tools
t DENY Read file_path '/repo/.env'
t DENY Read file_path '/repo/.env.production'
t ok   Read file_path '/repo/.env.example'
t ok   Read file_path '/repo/docroot/sites/default/settings.php'
t DENY Edit file_path '/repo/crypto-trading/secrets/binance.json'
t ok   Grep path '/repo/src'
t ok   Read file_path '/repo/src/environment.ts'

# malformed input must fail closed
printf 'not json' | "$HOOK" >/dev/null 2>&1
if [ $? -eq 2 ]; then echo 'PASS DENY malformed input'; else echo 'FAIL DENY malformed input'; fails=$((fails + 1)); fi

# missing jq must fail closed. /bin/bash is explicit because the shebang
# (#!/usr/bin/env bash) cannot resolve bash with an empty PATH.
err=$(printf '{}' | PATH=/nonexistent /bin/bash "$HOOK" 2>&1 >/dev/null); rc=$?
if [ $rc -eq 2 ] && [[ $err == *'jq no está instalado'* ]]; then
  echo 'PASS DENY missing jq'
else
  echo "FAIL DENY missing jq (rc=$rc)"; fails=$((fails + 1))
fi

echo "---- failures: $fails"
exit $fails
