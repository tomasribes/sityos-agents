# ceo-system en Codex CLI

> **Fecha de la revisión:** 2026-11-26 · **Codex CLI:** 0.172.0 (`/usr/local/lib/node_modules/@openai/codex/package.json`; el issue partía de 0.170.0) · **Plugin en el repo:** `ceo-system` 0.3.1 · **Issue:** DEV-52 (KR1.5 — Compatibilidad con Codex)
>
> Revisión estática: se han leído `~/.codex/` y la documentación oficial, y se ha ejecutado el script del hook con entradas JSON con la forma de Codex. No se ha ejecutado `codex`. Lo que solo se confirma ejecutando Codex queda como `sin verificar` y tiene su prueba en [Pruebas para el dueño](#pruebas-para-el-dueño).

## Resumen

**No uses ceo-system en Codex todavía.** Mientras siga habilitado en `~/.codex/config.toml` (`[plugins."ceo-system@sityos-agents"] enabled = true`):

1. Codex carga una **copia desfasada** del plugin (`~/.codex/plugins/cache/sityos-agents/ceo-system/0.3.1/`, del 2026-11-25 19:23). Su `ceo-run` y su `live-verify` hacen commit y push de `.ceo/ceo-log.md` **directamente en `develop`**, el comportamiento que retiró DEV-44.
2. Los agentes del plugin (`ceo`, `verifier`, `pm`) no son subagentes de Codex. Sus restricciones de herramientas (`tools:`, `disallowedTools:`) no se aplican.
3. No hay MCP de Linear habilitado. Todos los comandos dependen de Linear.
4. El guardarraíl solo corre si Codex lo descubre y el dueño lo marca como de confianza. Aun así, la copia en caché deja pasar `git -C <ruta> push origin master` y no revisa las ediciones hechas con `apply_patch`.

## Cómo llega el plugin a Codex

- `~/.codex/config.toml` declara el marketplace local `sityos-agents` (`source = "/Users/tomasribes/ai-projects/sityos-agents"`) y habilita `ceo-system@sityos-agents`. Codex lee el catálogo `.claude-plugin/marketplace.json` del repo, el formato "legacy-compatible" que documenta OpenAI ([Package your plugin · How local marketplaces work](https://developers.openai.com/codex/plugins/build)).
- Codex no carga el plugin desde el repo: lo copia a `~/.codex/plugins/cache/$MARKETPLACE/$PLUGIN/$VERSION/` ([misma página](https://developers.openai.com/codex/plugins/build)). La documentación dice que en los plugins locales `$VERSION` es `local`. Aquí la carpeta es `0.3.1`, la versión de `plugins/ceo-system/.claude-plugin/plugin.json`.
- **La copia no se refresca si no cambia la versión.** Desde la copia (2026-11-25 19:23) se han fusionado 9 commits en `plugins/ceo-system/` sin subir la versión (`git log --after='2026-11-25 19:00' -- plugins/ceo-system`). `diff -rq` entre la caché y el repo da 8 ficheros distintos: los 3 agentes, `ceo-run.md`, `dispatch.md`, `live-verify.md`, `deny-dangerous.sh` y su test.
- El plugin no tiene `.codex-plugin/plugin.json` ni `plugin.json` de raíz. Codex usa el manifiesto Claude (`.claude-plugin/plugin.json`) como compatibilidad y, en la caché, generó `.codex-plugin/migrated-command-skills/` con una skill por comando migrado.
- Componentes que documenta un plugin de Codex: `skills/`, `mcp.json`, hooks (`hooks/hooks.json` por defecto) y assets ([Package your plugin · Plugin structure](https://developers.openai.com/codex/plugins/build)). `agents/` y `commands/` no aparecen.

## Componentes

Estados: `funciona` · `no funciona` · `sin verificar`. Las rutas `~/.codex/...cache...` se refieren a `~/.codex/plugins/cache/sityos-agents/ceo-system/0.3.1/`.

| Componente | Qué hace Codex con él | Evidencia | Estado |
|---|---|---|---|
| `/ceo-system:ceo-run` | Lo convierte en la skill `source-command-ceo-run` con el texto del comando **anterior a DEV-44**: commit y push de `.ceo/ceo-log.md` directo a `develop`. Delega en `ceo-system:verifier` y `ceo-system:ceo`, que no son agentes de Codex (ver filas de agentes). Sin MCP de Linear. | `~/.codex/...cache.../.codex-plugin/migrated-command-skills/source-command-ceo-run/SKILL.md` (paso 6, "Commit del log … directo a la rama base, sin PR") · `diff` con `plugins/ceo-system/commands/ceo-run.md` del repo · `~/.codex/config.toml` sin MCP de Linear | `no funciona` |
| `/ceo-system:dispatch` | No lo convierte: no hay `source-command-dispatch`. Hipótesis sobre la causa en [Por qué falta dispatch](#por-qué-falta-dispatch). | `ls ~/.codex/...cache.../.codex-plugin/migrated-command-skills/` → solo `ceo-run`, `live-verify`, `pm-digest` | `no funciona` |
| `/ceo-system:live-verify` | Lo convierte en la skill `source-command-live-verify` con el texto **anterior a DEV-44**: commit y push del log directo a `develop`. Delega en `ceo-system:verifier`. Sin MCP de Linear. | `~/.codex/...cache.../.codex-plugin/migrated-command-skills/source-command-live-verify/SKILL.md` (paso 5) · `~/.codex/config.toml` | `no funciona` |
| `/ceo-system:pm-digest` | Lo convierte en la skill `source-command-pm-digest` (texto igual al del repo). Delega en `ceo-system:pm`, que no es un agente de Codex, y necesita Linear. | `~/.codex/...cache.../.codex-plugin/migrated-command-skills/source-command-pm-digest/SKILL.md` · `~/.codex/config.toml` sin MCP de Linear (`linear@openai-curated-remote` está en caché pero no habilitado) | `no funciona` |
| Agente `ceo-system:ceo` | Codex solo define agentes propios con TOML en `~/.codex/agents/` o `.codex/agents/` (`name`, `description`, `developer_instructions`). Un agente hereda permisos y MCP del padre y no puede restringirlos, así que `disallowedTools` (sin Bash, sin Write/Edit) no tendría efecto. La caché no tiene ninguna conversión de `agents/*.md`. | [Subagents · Custom agents](https://developers.openai.com/codex/subagents) · `~/.codex/agents/` no existe · `strings` del binario de Codex: 0 apariciones de `disallowedTools` | `no funciona` |
| Agente `ceo-system:verifier` | Igual que `ceo`. Sus `tools:` (solo lectura de Linear y Bash) no se aplicarían. Un `spawn_agent` con `agent_type` desconocido debería fallar (`unknown agent_type`, cadena del binario). | [Subagents · Custom agents](https://developers.openai.com/codex/subagents) · caché sin conversión de agentes | `no funciona` |
| Agente `ceo-system:pm` | Igual que `verifier`. | [Subagents · Custom agents](https://developers.openai.com/codex/subagents) · caché sin conversión de agentes | `no funciona` |
| `dev-plugin` (`.claude/agents/dev-plugin.md`) | Codex busca agentes de proyecto en `.codex/agents/*.toml`, no en `.claude/agents/`. Además solo lo lanza `dispatch`, que no existe en Codex. | [Subagents · Custom agents](https://developers.openai.com/codex/subagents) · el repo no tiene `.codex/` · `strings` del binario: 0 apariciones de `.claude/agents` | `no funciona` |
| Skill `ceo-system:linear-conventions` | `skills/` es un componente documentado de plugin, así que Codex debería ofrecerla. La copia en caché es igual a la del repo. Falta confirmar que aparece y con qué nombre (con o sin prefijo `ceo-system:`); los agentes y comandos la piden por ese nombre. | [Package your plugin · Plugin structure](https://developers.openai.com/codex/plugins/build) · `~/.codex/...cache.../skills/linear-conventions/SKILL.md` | `sin verificar` |
| Skill `ceo-system:pr-contract` | Igual que `linear-conventions`. | [Package your plugin](https://developers.openai.com/codex/plugins/build) · `~/.codex/...cache.../skills/pr-contract/SKILL.md` | `sin verificar` |
| Hook `PreToolUse` (`hooks/hooks.json` → `deny-dangerous.sh`) | Codex descubre `hooks/hooks.json` del plugin por defecto, define `CLAUDE_PLUGIN_ROOT` por compatibilidad, acepta `exit 2` + `stderr` para bloquear y mapea su shell a `Bash`. Pero: (1) no lo ejecuta hasta que el dueño lo revisa y lo marca como de confianza (`/hooks`); (2) un error o timeout del hook deja pasar la llamada; (3) las ediciones llegan como `tool_name: "apply_patch"`, que el script no trata (sale con 0); (4) Codex no tiene `Read`/`Grep`/`Glob` (lee con la shell); (5) la copia en caché es anterior al endurecimiento de opciones globales de git. | [Package your plugin · lifecycle hooks](https://developers.openai.com/codex/plugins/build) · [Hooks](https://developers.openai.com/codex/hooks) (Review and trust hooks, Tool coverage, PreToolUse) · prueba local, abajo | `sin verificar` |

### Prueba local del hook

Se pasó el mismo JSON por stdin a la copia en caché (`~/.codex/...cache.../hooks/deny-dangerous.sh`) y a la del repo. Las entradas tienen la forma que documenta Codex para `PreToolUse` (`tool_name`, `tool_input.command`). `exit=2` es bloqueo.

| Entrada | Caché 0.3.1 | Repo |
|---|---|---|
| `Bash` · `gh pr merge 999 --help` | exit=2 | exit=2 |
| `Bash` · `git -C . push origin master` | **exit=0** | exit=2 |
| `apply_patch` · parche que crea `.env` | **exit=0** | **exit=0** |
| `Bash` · `echo ok` | exit=0 | exit=0 |

Esto comprueba el script, no que Codex lo invoque. Eso queda para las pruebas del dueño.

### Por qué falta dispatch

Sin evidencia concluyente. Todas son hipótesis `sin verificar`:

- **Argumentos.** `dispatch.md` es el único comando con `argument-hint` y `$ARGUMENTS`. En contra: el binario de Codex contiene texto que explica `$ARGUMENTS` y `argument-hint`, así que el formato le resulta conocido.
- **Herramienta Agent con `isolation: "worktree"`.** Es el único comando que lanza agentes en worktrees. Codex tiene `spawn_agent` (el hook lo empareja también como `Agent`), pero no documenta `isolation`.
- **Tamaño.** Es el comando más largo de la copia (5195 bytes frente a 2486 de `ceo-run`).

Aunque se convirtiera, no funcionaría: necesita Linear, agentes con nombre (`agents.<role>`) y worktrees aislados por agente.

## Pruebas para el dueño

Ejecuta cada prueba desde `~/ai-projects/sityos-agents` (proyecto `trusted` en `config.toml`). `codex exec` corre por defecto con sandbox de solo lectura ([Non-interactive mode](https://developers.openai.com/codex/noninteractive)). Las pruebas 1–3 necesitan el plugin habilitado: si ya lo has desactivado, ponlo en `enabled = true` solo para la prueba y vuelve a `false` al acabar. Nada de lo que sigue escribe en Linear ni en git.

### 1. ¿Codex descubre el hook? (fila: hook)

```bash
codex
# dentro del TUI:
/hooks
```

Esperado: una entrada `PreToolUse` con origen el plugin `ceo-system` y matcher `Bash|Read|Edit|Write|MultiEdit|NotebookEdit|Grep|Glob`, marcada como pendiente de revisión. Si no aparece, el hook **no funciona** en Codex. Si aparece, márcalo como de confianza solo para las pruebas 2 y 3.

### 2. ¿El hook bloquea? (fila: hook)

Comando inofensivo que `deny-dangerous.sh` bloquea (`gh pr merge --help` solo imprime la ayuda):

```bash
codex exec --ephemeral "Ejecuta exactamente este comando de shell, sin cambiarlo, y dime su salida y su código de salida: gh pr merge --help"
```

Esperado si **funciona**: la llamada se bloquea con `Bloqueado por guardarrail ceo-system: merge de PR (solo el dueño mergea)…` y no aparece la ayuda de `gh`. Si aparece la ayuda, el hook **no funciona**.

Sin trust persistente, para una sola ejecución:

```bash
codex exec --ephemeral --dangerously-bypass-hook-trust "Ejecuta exactamente este comando de shell, sin cambiarlo, y dime su salida y su código de salida: gh pr merge --help"
```

### 3. ¿Qué copia del hook corre? (fila: hook)

```bash
codex exec --ephemeral "Ejecuta exactamente este comando de shell, sin cambiarlo, y dime su salida y su código de salida: git -C /tmp push origin master --dry-run"
```

Esperado con la copia en caché 0.3.1: **no se bloquea**; git falla con `not a git repository` (en `/tmp` no hay repo, no se empuja nada). Con la versión del repo: `Bloqueado por guardarrail ceo-system: push a master/main`.

### 4. ¿Existe el subagente del verificador? (filas: agentes y `dev-plugin`)

```bash
codex exec --ephemeral "No ejecutes comandos de shell. Usa spawn_agent con agent_type 'ceo-system:verifier' y la tarea 'Responde solo OK'. Repite con agent_type 'verifier' y con 'dev-plugin'. Para cada intento dime si se lanzó o el error exacto. Después lista los agent_type que acepta spawn_agent."
```

Esperado (confirma `no funciona`): los tres intentos fallan con `unknown agent_type …` y la lista solo incluye los agentes integrados (`default`, `worker`, `explorer`). Si alguno se lanza, revisa si respeta sus restricciones antes de cambiar el estado de la fila.

### 5. ¿Ve Codex las skills del plugin? (filas: skills y comandos)

```bash
codex exec --ephemeral "No ejecutes comandos de shell. Lista las skills disponibles cuyo nombre contenga linear-conventions, pr-contract o source-command, con el nombre exacto y la ruta del SKILL.md."
```

Esperado: `linear-conventions` y `pr-contract` con ruta bajo `~/.codex/plugins/cache/sityos-agents/ceo-system/0.3.1/skills/`, y las tres `source-command-*` (sin `dispatch`). Anota si el nombre lleva el prefijo `ceo-system:`. Si no aparecen `linear-conventions` y `pr-contract`, esas filas pasan a `no funciona`.

### 6. ¿Hay Linear en Codex? (filas: comandos)

```bash
codex exec --ephemeral "No ejecutes comandos de shell. Lista las herramientas MCP disponibles cuyo nombre contenga linear, con su nombre completo."
```

Esperado hoy: ninguna. Si habilitas `linear@openai-curated-remote`, anota el nombre real de las herramientas: los agentes del plugin usan `mcp__claude_ai_Linear__*`.

### 7. ¿Se refresca la caché? (fila: dispatch)

Después de subir la versión del plugin (cambio propuesto 2) y de que Codex reinstale:

```bash
ls ~/.codex/plugins/cache/sityos-agents/ceo-system/
ls ~/.codex/plugins/cache/sityos-agents/ceo-system/*/.codex-plugin/migrated-command-skills/
```

Esperado: una carpeta con la versión nueva y, si alguna de las hipótesis de arriba era la causa y ya no aplica, `source-command-dispatch`. Si sigue faltando con la versión nueva, la causa sigue sin conocerse.

## Cambios propuestos

Cada línea es un issue candidato. **human_only** = toca `zones.human_only` de `.ceo/config.yml`. "Dueño" = cambio en la máquina del dueño, fuera del repo (equipo TOM).

| # | Issue propuesto | Zona | human_only |
|---|---|---|---|
| 1 | Desactivar `ceo-system` en Codex hasta cerrar KR1.5 (`enabled = false` en `~/.codex/config.toml`) | `~/.codex/config.toml` | Dueño (fuera del repo) |
| 2 | Subir la versión de `ceo-system` en cada cambio publicado para que Codex refresque su copia | `plugins/ceo-system/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (relacionado con KR1.2) | **Sí** |
| 3 | Añadir un manifiesto Codex que exponga solo las skills y el hook, sin migrar comandos | `plugins/ceo-system/.codex-plugin/plugin.json` (o `extensions.com.openai` en un `plugin.json` de raíz) | **Sí** en la práctica: `.codex-plugin/` no está en `zones`; añadirlo a `human_only` (`.ceo/config.yml`, también human_only) |
| 4 | Cubrir `apply_patch` en el guardarraíl: rutas de secretos dentro del parche, con casos en el test | `plugins/ceo-system/hooks/deny-dangerous.sh`, `plugins/ceo-system/tests/deny-dangerous.test.sh` | **Sí** (hook) |
| 5 | Hacer que los comandos de `ceo-system` paren con un aviso si no corren en Claude Code | `plugins/ceo-system/commands/*.md` | No |
| 6 | Decidir si ceo-system se porta a Codex (agentes TOML en `.codex/agents/`, `spawn_agent`, MCP de Linear) o se declara solo para Claude Code | Decisión del dueño; después `docs/compat/codex.md` y `README.md` | No (decisión: `needs-human`) |
| 7 | Habilitar un MCP de Linear en Codex y documentar el nombre de sus herramientas (solo si se elige portar en el 6) | `~/.codex/config.toml` | Dueño (fuera del repo) |
| 8 | Regenerar el `AGENTS.md` global de Codex desde `global/CLAUDE.md` | `global/**`, `install-sityos-agents.sh` | **Sí** |

Nota sobre el 8: `~/.codex/AGENTS.md` (2026-11-19) es una conversión antigua de `global/CLAUDE.md`. Hoy no contiene las rutas citadas en DEV-52 (`~/.Codex/commands/`, `.Codex/settings.json`, `Codex-api`), pero sí otras sustituciones erróneas: `Codex-sonnet` (línea 36), `Codex API` (línea 50) y el enlace `Codex: https://docs.anthropic.com/en/docs/claude-code/overview` (línea 240). Además describe un entorno anterior (DDEV en la línea 66).

Orden recomendado: 1 ya; 2 y 4 antes de volver a habilitar el plugin; 6 decide si 3, 5 y 7 se hacen.
