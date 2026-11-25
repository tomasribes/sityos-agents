---
description: Run the CEO planning cycle for the project of the current repo (live verification, then goals.md -> Linear issues in Proposed)
---

Ejecuta el ciclo del CEO sobre el repo actual. Pasos, en orden:

1. Si existe `.ceo/PAUSE` en la raíz del repo, responde `Repo en pausa (.ceo/PAUSE)` y termina.
2. Comprueba que existen `goals.md` y `.ceo/config.yml` en la raíz del repo. Por cada fichero que falte, responde una línea y termina:
   - `Falta goals.md`: objetivos, Key Results y la lista de **Active milestones** del periodo, escritos por el dueño.
   - `Falta .ceo/config.yml`: el contrato CEO del repo (`linear.team`, `linear.project`, `linear.states`, `branches.base`, `limits`, `autonomy`, `zones`).

   No delegues en ningún subagente, no escribas en Linear y no publiques el log.
3. Lee `linear.project` de `.ceo/config.yml`. Si el proyecto de Linear tiene el **project label** `agent-paused`, responde `Proyecto en pausa (agent-paused)` y termina. No delegues en ningún subagente ni escribas el log.
4. **Verificación en producción.** Delega en el subagente `ceo-system:verifier`. Pásale la ruta absoluta del repo y la fecha actual en UTC. Espera a que termine antes de seguir, para que el CEO planifique con los estados al día. Si falla, registra el error (ver abajo) y sigue con el paso 5.
5. Delega en el subagente `ceo-system:ceo` el ciclo completo. Pásale la ruta absoluta del repo y la fecha actual en UTC. No añadas instrucciones propias ni reinterpretes las suyas. No le pases la respuesta del verificador: el CEO lee el resultado en Linear.
6. Cuando terminen, toma literalmente el bloque bajo `## Log` de cada respuesta, primero el del verificador y después el del CEO. Esa es la entrada: publícala con el bloque **Publicar el log** (al final de este fichero).
7. Muéstrame solo los bloques de Informe: primero el del verificador, con el encabezado `## Verificación en producción`; después el del CEO, con el encabezado `## Informe`.

Si un subagente falla o no devuelve los dos bloques, añade igualmente al log una entrada `### <fecha> · ERROR` (`### <fecha> · live-verify · ERROR` para el verificador) con el motivo y dímelo.

Las entradas de ERROR también se publican con **Publicar el log**.

## Publicar el log

La entrada nunca se escribe ni se commitea en el checkout principal ni en la rama base. Va como commit nuevo en la rama `ceo-log`, que tiene un único PR abierto contra la base y acumula las entradas hasta que el dueño lo fusiona con merge commit. `<base>` es `branches.base` de `.ceo/config.yml` (`develop` si no está). `WT` es `.claude/worktrees/ceo-log`, relativo a la raíz del repo. Ejecuta los comandos desde la raíz del repo, en este orden. Si un paso falla (salvo el segundo `git fetch` del paso 1), ve al paso 8.

1. `git fetch origin <base>` y después `git fetch origin ceo-log`. El segundo falla si la rama remota no existe: no es un error.
2. `gh pr list --head ceo-log --base <base> --state open --json number --jq length`. Si da `1` o más, hay PR abierto y el punto de partida es `origin/ceo-log`. Si da `0`, no hay PR y el punto de partida es `origin/<base>`.
3. Prepara `WT`:
   - Si no existe: `git worktree add -B ceo-log .claude/worktrees/ceo-log <punto de partida>`.
   - Si existe y `git -C .claude/worktrees/ceo-log status --porcelain` no está vacío, o la rama tiene upstream y `git -C .claude/worktrees/ceo-log rev-list @{u}..HEAD` no está vacío (commits sin publicar): no toques nada y ve al paso 8 con el motivo `worktree ceo-log con cambios o commits sin publicar`.
   - Si existe y está limpio: `git -C .claude/worktrees/ceo-log switch -C ceo-log <punto de partida>`.
4. Añade la entrada al final de `.claude/worktrees/ceo-log/.ceo/ceo-log.md` (créalo con el encabezado `# CEO log` si no existe). Es el único fichero que tocas. Nunca escribas en `.ceo/ceo-log.md` del checkout principal.
5. `git -C .claude/worktrees/ceo-log add .ceo/ceo-log.md` y `git -C .claude/worktrees/ceo-log commit -m "Update CEO log: ceo-run <fecha UTC>" -- .ceo/ceo-log.md`. Solo ese fichero. Sin trailers.
6. `git -C .claude/worktrees/ceo-log push -u origin ceo-log`. Nunca forzado y nunca a otra rama. Si se rechaza (por ejemplo, el PR anterior se fusionó con squash y la rama remota sigue ahí), ve al paso 8.
7. Si en el paso 2 no había PR: `gh pr create --base <base> --head ceo-log --title "CEO log" --body "Entradas de .ceo/ceo-log.md escritas por ceo-run, dispatch y live-verify. Fusionar con merge commit."`.
8. Si algo falla: no reintentes, no fuerces nada y no toques el checkout principal. Añade al final de tu respuesta `ceo-log sin publicar: <motivo>` y muestra la entrada completa para que no se pierda.
