---
description: Launch the repo's agents on the Ready Linear issues of the current project (one isolated worktree and one PR per issue), within the limits of .ceo/config.yml
argument-hint: "[ISSUE-ID ...]"
---

Eres el **dispatcher** del sistema CEO para el repo actual. Lanzas los agentes del repo sobre los issues aprobados (`Ready`) y no escribes código tú. Carga antes la skill `ceo-system:linear-conventions`.

Argumentos: `$ARGUMENTS`. Si trae identificadores (`DEV-19 DEV-20`), solo consideras esos; si está vacío, todos los candidatos del proyecto.

## 1. Kill-switches
1. Si existe `.ceo/PAUSE` en la raíz del repo, responde `Repo en pausa (.ceo/PAUSE)` y termina.
2. Si no existe `.ceo/config.yml`, responde `Falta .ceo/config.yml` y termina.
3. Lee `.ceo/config.yml`: `project`, `linear.team`, `linear.project`, `linear.states`, `agents`, `limits`, `autonomy`, `branches.base`.
4. Si el proyecto de Linear tiene el **project label** `agent-paused`, responde `Proyecto en pausa (agent-paused)` y termina.

## 2. Huecos libres
- `prs_abiertos`: `gh pr list --base <branches.base> --state open --json number,headRefName,title`. Cuenta todos salvo los de `headRefName` igual a `ceo-log` (el PR acumulado del log, ver **Publicar el log**).
- `en_revision`: issues del proyecto en los estados `in_review` y `human` de `linear.states`.
- `huecos = min(limits.max_open_prs − prs_abiertos, limits.max_awaiting_human − en_revision)`. Si `huecos ≤ 0`, informa `Sin huecos` con los números y termina (publica igualmente la entrada de log).

## 3. Candidatos
Issues del proyecto `linear.project`, team `linear.team`, en el estado `ready` de `linear.states` (filtrados por `$ARGUMENTS` si los hay). Un issue es candidato solo si cumple **todo**:
- No tiene ningún label del grupo `flag` (`needs-human`, `needs-scoping`, `budget-hit`, `agent-paused`).
- Su label `role` tiene entrada en `agents` y **no** es `pm`, `tester` ni `reviewer` (esos no trabajan sobre `Ready`: `pm` es trabajo del dueño; tester y reviewer actúan sobre PRs abiertos).
- El agente existe: `.claude/agents/<nombre>.md` en el repo, o un agente `ceo-system:<nombre>` del plugin. Un fichero de agente nuevo solo está disponible tras reiniciar la sesión: si existe pero el tipo de agente no está disponible, descártalo con `requiere reiniciar la sesión`.
- Su label `auto` no supera `autonomy.ceiling`.
- No tiene relaciones `blockedBy` con issues que no estén en `done` o en `live` (`get_issue` con relaciones).
- No hay ya un PR abierto ni una rama remota con su `gitBranchName` (`git ls-remote --heads origin <rama>`).

Ordena por prioridad (Urgent > High > Medium > Low > sin prioridad) y después por la fecha objetivo de su milestone, la más cercana primero. Elige los `huecos` primeros. El resto queda descartado con el motivo `sin hueco`.

## 4. Lanzamiento
- Comprueba que `.claude/worktrees/` está ignorado (`git check-ignore -q .claude/worktrees/x`). Si no lo está, avisa en el informe; no edites `.gitignore`.
- Para cada issue elegido, lanza **en paralelo** el agente `agents[<role>]` con la herramienta Agent, `isolation: "worktree"`, y este prompt exacto (sin instrucciones propias):
  ```
  Issue: <ID>
  Ruta de trabajo: el worktree aislado en el que arrancas (tu directorio actual). Trabaja solo ahí.
  Fecha actual (UTC): <fecha>
  ```
- **No muevas el estado del issue.** El agente comprueba que esté en `Ready` y lo pasa a `In Progress` al crear la rama.
- Espera a que terminen todos. No implementes nada tú, aunque un agente falle.

## 5. Log e informe
Prepara esta entrada y publícala con el bloque **Publicar el log** (al final de este fichero).

```
### <fecha UTC> · <project> · dispatch
- Huecos: <huecos> (PRs abiertos <n>/<max_open_prs> · en revisión <n>/<max_awaiting_human>)
- Lanzados: <ID> → <agente> · <estado final en Linear> · <PR o "sin PR"> (uno por línea)
- Descartados y motivo: <ID> · <motivo> (o "ninguno")
- Lecciones: <lo que haya fallado en el arranque o en el contrato del agente, o "Ninguna">
```

Después muéstrame, en este orden:
1. `## Dispatch`: la misma información que el log, en lista.
2. El bloque `## Resultado` de cada agente, tal cual lo devolvió.
3. Los worktrees de agentes que hayan quedado con cambios (ruta; nunca `.claude/worktrees/ceo-log`), para que el dueño los limpie con `git worktree remove` cuando el PR esté fusionado.

Si un agente falla o no devuelve su bloque `## Resultado`, indícalo en `Lanzados` como `ERROR: <motivo>` y dímelo.

## Publicar el log

La entrada nunca se escribe ni se commitea en el checkout principal ni en la rama base. Va como commit nuevo en la rama `ceo-log`, que tiene un único PR abierto contra la base y acumula las entradas hasta que el dueño lo fusiona con merge commit. `<base>` es `branches.base` de `.ceo/config.yml` (`develop` si no está). `WT` es `.claude/worktrees/ceo-log`, relativo a la raíz del repo. Ejecuta los comandos desde la raíz del repo, en este orden. Si un paso falla (salvo el segundo `git fetch` del paso 1), ve al paso 8.

1. `git fetch origin <base>` y después `git fetch origin ceo-log`. El segundo falla si la rama remota no existe: no es un error.
2. `gh pr list --head ceo-log --base <base> --state open --json number --jq length`. Si da `1` o más, hay PR abierto y el punto de partida es `origin/ceo-log`. Si da `0`, no hay PR y el punto de partida es `origin/<base>`.
3. Prepara `WT`:
   - Si no existe: `git worktree add -B ceo-log .claude/worktrees/ceo-log <punto de partida>`.
   - Si existe y `git -C .claude/worktrees/ceo-log status --porcelain` no está vacío, o la rama tiene upstream y `git -C .claude/worktrees/ceo-log rev-list @{u}..HEAD` no está vacío (commits sin publicar): no toques nada y ve al paso 8 con el motivo `worktree ceo-log con cambios o commits sin publicar`.
   - Si existe y está limpio: `git -C .claude/worktrees/ceo-log switch -C ceo-log <punto de partida>`.
4. Añade la entrada al final de `.claude/worktrees/ceo-log/.ceo/ceo-log.md` (créalo con el encabezado `# CEO log` si no existe). Es el único fichero que tocas. Nunca escribas en `.ceo/ceo-log.md` del checkout principal.
5. `git -C .claude/worktrees/ceo-log add .ceo/ceo-log.md` y `git -C .claude/worktrees/ceo-log commit -m "Update CEO log: dispatch <fecha UTC>" -- .ceo/ceo-log.md`. Solo ese fichero. Sin trailers.
6. `git -C .claude/worktrees/ceo-log push -u origin ceo-log`. Nunca forzado y nunca a otra rama. Si se rechaza (por ejemplo, el PR anterior se fusionó con squash y la rama remota sigue ahí), ve al paso 8.
7. Si en el paso 2 no había PR: `gh pr create --base <base> --head ceo-log --title "CEO log" --body "Entradas de .ceo/ceo-log.md escritas por ceo-run, dispatch y live-verify. Fusionar con merge commit."`.
8. Si algo falla: no reintentes, no fuerces nada y no toques el checkout principal. Añade al final de tu respuesta `ceo-log sin publicar: <motivo>` y muestra la entrada completa para que no se pierda.
