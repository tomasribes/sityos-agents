---
description: Launch the repo's reviewer agent (agents.reviewer in .ceo/config.yml) on the open agent PRs whose issue is In Review - one read-only review per PR at a pinned head SHA
argument-hint: "[PR-NUMBER ...]"
---

Eres el **lanzador de revisiones** del sistema CEO para el repo actual. Lanzas el agente revisor sobre PRs abiertos y no revisas nada tú. Carga antes la skill `ceo-system:linear-conventions`.

Argumentos: `$ARGUMENTS`. Si trae números de PR (`12 15`), solo consideras esos; si está vacío, todos los candidatos.

## 1. Kill-switches
1. Si existe `.ceo/PAUSE`, responde `Repo en pausa (.ceo/PAUSE)` y termina.
2. Si no existe `.ceo/config.yml`, responde `Falta .ceo/config.yml` y termina.
3. Lee `.ceo/config.yml`: `project`, `linear.project`, `linear.states`, `agents`, `branches.base`.
4. Si el proyecto de Linear tiene el project label `agent-paused`, responde `Proyecto en pausa (agent-paused)` y termina.
5. Si `agents.reviewer` no existe, o no es ni un fichero `.claude/agents/<nombre>.md` ni un agente `ceo-system:<nombre>` disponible, responde `Sin agente revisor (agents.reviewer)` y termina.

## 2. Candidatos
`gh pr list --base <branches.base> --state open --json number,title,headRefName,headRefOid,isDraft`. Un PR es candidato solo si cumple **todo**:
- No es `ceo-log` (`headRefName`) ni draft.
- Su título empieza por el identificador de un issue (`DEV-123:`) y ese issue está en el estado `in_review` de `linear.states`, sin ningún label del grupo `flag`.
- No tiene ya una revisión de este agente para su head: ningún comentario del PR (`gh pr view <n> --json comments`) contiene `Head revisado: <sha corto de headRefOid>`.

Como máximo **3** por ejecución, los más antiguos primero. El resto queda como `sin hueco`.

## 3. Lanzamiento
Para cada candidato, lanza **en paralelo** el agente `agents.reviewer` con la herramienta Agent (sin worktree: el revisor no escribe en el repo) y este prompt exacto:
```
PR: <número>
Issue: <ID>
Head: <headRefOid completo>
Fecha actual (UTC): <fecha>
```
Espera a que terminen todos. No revises nada tú, aunque un agente falle.

## 4. Informe
Este comando no escribe en `.ceo/ceo-log.md`: el rastro queda en los comentarios de los PRs y de los issues. Muéstrame:
1. `## Review`: `<PR> · <issue> · <veredicto> · <estado en Linear>` por línea, más los descartados con su motivo (`no In Review`, `flag <label>`, `ya revisado en <sha>`, `draft`, `sin issue en el título`, `sin hueco`).
2. El bloque `## Resultado` de cada agente, tal cual. Si un agente falla o no lo devuelve, `ERROR: <motivo>`.
