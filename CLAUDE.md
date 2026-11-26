@AGENTS.md

## Plugin local

```bash
claude --plugin-dir ./plugins/ceo-system
```

Carga el working tree solo para esa sesión, sin instalar nada ni tocar `~/.claude`.

Este repo también consume el plugin como cualquier otro: `.claude/settings.json` lo
habilita por proyecto fijado al último tag publicado (`ceo-system-v0.4.0`), así que
`/ceo-system:dispatch` y los demás comandos corren la versión publicada, nunca la
del working tree. Al publicar un tag nuevo, sube `ref` en un PR a `develop`.

## Versión

```bash
jq -r '.metadata.version, .plugins[0].version' .claude-plugin/marketplace.json
jq -r .version plugins/ceo-system/.claude-plugin/plugin.json
claude plugin list --json | jq '.[] | select(.id == "ceo-system@sityos-agents") | {version, scope, enabled}'
```

Las dos primeras deben dar la misma versión. La tercera muestra la versión instalada
en caché, la que carga una sesión normal (con `--plugin-dir` se carga el working tree).

## Puntos de entrada

- `/ceo-system:ceo-run` — verificación live y `goals.md` → issues en Proposed.
- `/ceo-system:dispatch` — lanza los agentes sobre los issues Ready → PRs a `develop`.
- `/ceo-system:live-verify` — Pending live → Done o Blocked.
- `/ceo-system:pm-digest` — digest diario de los proyectos CEO.

Escriben en Linear o GitHub (`pm-digest` solo lee de ambos). Solo los lanza el
dueño: un agente nunca los ejecuta para probarlos.
