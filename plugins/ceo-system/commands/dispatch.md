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

## 1b. Lock de ejecución
Solo un dispatch a la vez por clon. El directorio común de git es el mismo desde el checkout principal y desde cualquier worktree, así que el lock lo comparten todas las sesiones del clon. No se versiona.

1. Desde la raíz del repo, ejecuta `mkdir "$(git rev-parse --git-common-dir)/ceo-dispatch.lock"`.
2. Si falla porque el directorio ya existe, otro dispatch está en curso o uno anterior quedó a medias. Calcula `<ruta>` = `"$(git rev-parse --path-format=absolute --git-common-dir)/ceo-dispatch.lock"` y `<fecha>` = la fecha que muestra `ls -ld <ruta>`. Responde exactamente:
   ```
   Dispatch en curso (lock <ruta> desde <fecha>)
   Si no hay otro dispatch en marcha, el lock es huérfano. Quítalo a mano con: rmdir "<ruta>"
   ```
   y termina. No escribas en Linear, no lances agentes, no publiques el log y **no borres el lock**: un lock huérfano nunca se quita solo, lo quita el dueño con ese `rmdir`.
3. Si falla por otro motivo (permisos, ruta inexistente), responde `No se pudo crear el lock: <error>` y termina igual, sin efectos.
4. Si se crea, el lock es tuyo. Desde aquí, **toda salida** termina con **Liberar el lock** (al final de este fichero) como último paso, después de **Publicar el log**. Las salidas posibles son: `Sin huecos` (paso 2), ningún candidato (paso 3), el final normal tras los agentes (paso 5), un fallo de agente (paso 5), un fallo al publicar el log (paso 8 de **Publicar el log**) y cualquier error inesperado de `gh`, `git` o Linear. Ninguna de ellas deja el lock puesto.

## 1c. Base fijada
Una sola vez por ejecución, desde la raíz del repo y con `<base>` = `branches.base` (`develop` si no está):

1. `git fetch origin <base>`.
2. `BASE_SHA=$(git rev-parse origin/<base>)`. `<sha corto>` = `git rev-parse --short <BASE_SHA>`.

`BASE_SHA` no se vuelve a calcular en esta ejecución, aunque **Publicar el log** haga otro `git fetch origin <base>`: es la base que reciben todos los agentes y contra la que se comprueban sus ramas. Aparece en la línea `Huecos` del log como `base <base>@<sha corto>`. Si alguno de los dos comandos falla, es un error inesperado de `git`: no lances agentes, escribe en la línea `Huecos` `base sin fijar (<error>)`, publica el log y libera el lock.

## 2. Huecos libres
- `prs_abiertos`: `gh pr list --base <branches.base> --state open --json number,headRefName,title`. Cuenta todos salvo los de `headRefName` igual a `ceo-log` (el PR acumulado del log, ver **Publicar el log**).
- `en_revision`: issues del proyecto en los estados `in_review` y `human` de `linear.states`.
- `huecos = min(limits.max_open_prs − prs_abiertos, limits.max_awaiting_human − en_revision)`. Si `huecos ≤ 0`, informa `Sin huecos` con los números, publica igualmente la entrada de log, libera el lock (**Liberar el lock**) y termina.

## 3. Candidatos
Issues del proyecto `linear.project`, team `linear.team`, en el estado `ready` de `linear.states` (filtrados por `$ARGUMENTS` si los hay). Un issue es candidato solo si cumple **todo**:
- No tiene ningún label del grupo `flag` (`needs-human`, `needs-scoping`, `budget-hit`, `agent-paused`).
- Su label `role` tiene entrada en `agents` y **no** es `pm`, `tester` ni `reviewer` (esos no trabajan sobre `Ready`: `pm` es trabajo del dueño; tester y reviewer actúan sobre PRs abiertos).
- El agente existe: `.claude/agents/<nombre>.md` en el repo, o un agente `ceo-system:<nombre>` del plugin. Un fichero de agente nuevo solo está disponible tras reiniciar la sesión: si existe pero el tipo de agente no está disponible, descártalo con `requiere reiniciar la sesión`.
- Su label `auto` no supera `autonomy.ceiling`.
- No tiene relaciones `blockedBy` con issues que no estén en `done` o en `live` (`get_issue` con relaciones).
- No hay ya un PR abierto ni una rama remota con su `gitBranchName` (`git ls-remote --heads origin <rama>`).

Ordena por prioridad (Urgent > High > Medium > Low > sin prioridad) y después por la fecha objetivo de su milestone, la más cercana primero. Elige los `huecos` primeros. El resto queda descartado con el motivo `sin hueco`. Si no queda ningún candidato, salta al paso 5 (log con `Lanzados: ninguno`) y después libera el lock.

## 4. Lanzamiento
- Comprueba que `.claude/worktrees/` está ignorado (`git check-ignore -q .claude/worktrees/x`). Si no lo está, avisa en el informe; no edites `.gitignore`.
- **Relectura justo antes de lanzar.** Para cada issue elegido, vuelve a llamar a `get_issue` con relaciones inmediatamente antes de lanzar su agente. Si ya no está en el estado `ready` de `linear.states`, tiene algún label del grupo `flag` o tiene un `blockedBy` con un issue que no está en `done` ni en `live`:
  - no lances su agente y no cambies nada en él (ni estado, ni labels, ni comentarios);
  - añádelo a `Descartados` con el motivo `cambió antes de lanzar (<estado actual o label flag o blockedBy ID>)`, por ejemplo `cambió antes de lanzar (Proposed)` o `cambió antes de lanzar (needs-human)`;
  - su hueco queda libre en esta ejecución: no elijas otro candidato para ocuparlo.
- Para cada issue que siga siendo válido tras la relectura, lanza **en paralelo** el agente `agents[<role>]` con la herramienta Agent, `isolation: "worktree"`, y este prompt exacto (sin instrucciones propias):
  ```
  Issue: <ID>
  Ruta de trabajo: el worktree aislado en el que arrancas (tu directorio actual). Trabaja solo ahí.
  Fecha actual (UTC): <fecha>
  Base: origin/<base> @ <BASE_SHA>. Crea tu rama desde ese commit.
  ```
  `<BASE_SHA>` va completo (40 caracteres), el fijado en **1c. Base fijada**.
- **No muevas el estado del issue.** El agente comprueba que esté en `Ready` y lo pasa a `In Progress` al crear la rama.
- Espera a que terminen todos. No implementes nada tú, aunque un agente falle.

## 4b. Comprobación de la base
Cuando hayan terminado todos los agentes, comprueba cada issue lanzado cuya rama (`gitBranchName`) exista en el remoto (`git ls-remote --heads origin <rama>` no vacío). Los que no la empujaron no se comprueban.

1. `git fetch origin <rama>`.
2. `git merge-base --is-ancestor <BASE_SHA> origin/<rama>`. Exit 0: la rama parte de la base fijada (o la contiene), correcto.
3. Exit 1: la rama no contiene la base (por ejemplo, el worktree arrancó en `master`). En `Lanzados` marca ese issue `ERROR: rama no contiene base <sha corto>`.
4. Cualquier otro fallo de los pasos 1 o 2: márcalo `ERROR: no se pudo comprobar la base (<error>)`.

En los casos 3 y 4 **no toques el issue ni el PR**: ni estado, ni labels, ni comentarios, ni cierre. Lo decide el dueño con la entrada del log.

## 5. Log e informe
Prepara esta entrada y publícala con el bloque **Publicar el log** (al final de este fichero).

```
### <fecha UTC> · <project> · dispatch
- Huecos: <huecos> (PRs abiertos <n>/<max_open_prs> · en revisión <n>/<max_awaiting_human>) · base <base>@<sha corto>
- Lanzados: <ID> → <agente> · <estado final en Linear> · <PR o "sin PR"> (uno por línea)
- Descartados y motivo: <ID> · <motivo> (o "ninguno")
- Lecciones: <lo que haya fallado en el arranque o en el contrato del agente, o "Ninguna">
```

Después muéstrame, en este orden:
1. `## Dispatch`: la misma información que el log, en lista.
2. El bloque `## Resultado` de cada agente, tal cual lo devolvió.
3. Los worktrees de agentes que hayan quedado con cambios (ruta; nunca `.claude/worktrees/ceo-log`), para que el dueño los limpie con `git worktree remove` cuando el PR esté fusionado.

Si un agente falla o no devuelve su bloque `## Resultado`, indícalo en `Lanzados` como `ERROR: <motivo>` y dímelo. Publica igualmente el log y después libera el lock.

Tras **Publicar el log** (haya ido bien o haya acabado en su paso 8), ejecuta **Liberar el lock**. Es siempre el último paso.

## Publicar el log

La entrada nunca se escribe ni se commitea en el checkout principal ni en la rama base. Va como commit nuevo en la rama `ceo-log`, que tiene un único PR abierto contra la base y acumula las entradas hasta que el dueño lo fusiona con merge commit. `<base>` es `branches.base` de `.ceo/config.yml` (`develop` si no está). `WT` es `.claude/worktrees/ceo-log`, relativo a la raíz del repo. Ejecuta los comandos desde la raíz del repo, en este orden. Si un paso falla (salvo el segundo `git fetch` del paso 1), ve al paso 8.

1. `git fetch origin <base>` y después `git fetch origin ceo-log`. El segundo falla si la rama remota no existe: no es un error.
2. `gh pr list --head ceo-log --base <base> --state open --json number --jq length`. Si da `1` o más, hay PR abierto y el punto de partida es `origin/ceo-log`. Si da `0`, no hay PR y el punto de partida es `origin/<base>`.
3. Prepara `WT`:
   - Si no existe: `git worktree add -B ceo-log .claude/worktrees/ceo-log <punto de partida>`.
   - Si existe y `git -C .claude/worktrees/ceo-log status --porcelain` no está vacío, o la rama tiene upstream y `git -C .claude/worktrees/ceo-log rev-list @{u}..HEAD` no está vacío (commits sin publicar): no toques nada y ve al paso 8 con el motivo `worktree ceo-log con cambios o commits sin publicar`.
   - Si existe y está limpio: `git -C .claude/worktrees/ceo-log switch -C ceo-log <punto de partida>`.
4. Completa la entrada con dos líneas y añádela al final de `.claude/worktrees/ceo-log/.ceo/ceo-log.md` (créalo con el encabezado `# CEO log` si no existe). Es el único fichero que tocas. Nunca escribas en `.ceo/ceo-log.md` del checkout principal. Las entradas `ERROR` también llevan las dos líneas.
   - Justo debajo de cada encabezado `###` de la entrada, la línea `- Ejecución: <run_id> · ceo-system <versión> · <repo>`. Calcula los valores una sola vez: si la entrada tiene varios encabezados (en `ceo-run`, el del verificador y el del CEO), todos llevan la misma línea.
     - `<run_id>` = `<comando>-<UTC>`. `<comando>` es el de este fichero (`ceo-run`, `dispatch` o `live-verify`) y `<UTC>` es la salida de `date -u +%Y%m%dT%H%M%SZ`. Ejemplo: `dispatch-20261126T091500Z`.
     - `<versión>` = salida de `claude plugin list --json | jq -r '.[] | select(.id == "ceo-system@sityos-agents") | .version'`. Si está vacía o el comando falla, `desconocida`; nunca la deduzcas de otro sitio.
     - `<repo>` = salida de `gh repo view --json nameWithOwner -q .nameWithOwner`.
   - Al final de la entrada, una sola vez aunque tenga varios encabezados, la línea `- Errores: <lista o "ninguno">`. Recoge, separados por ` · `, el fallo de un subagente, un bloque `## Log` ausente y cada `ERROR:` de `Lanzados`. Nunca incluye `ceo-log sin publicar`: ese caso no llega al fichero.
5. `git -C .claude/worktrees/ceo-log add .ceo/ceo-log.md` y `git -C .claude/worktrees/ceo-log commit -m "Update CEO log: dispatch <fecha UTC>" -- .ceo/ceo-log.md`. Solo ese fichero. Sin trailers.
6. `git -C .claude/worktrees/ceo-log push -u origin ceo-log`. Nunca forzado y nunca a otra rama. Si se rechaza (por ejemplo, el PR anterior se fusionó con squash y la rama remota sigue ahí), ve al paso 8.
7. Si en el paso 2 no había PR: `gh pr create --base <base> --head ceo-log --title "CEO log" --body "Entradas de .ceo/ceo-log.md escritas por ceo-run, dispatch y live-verify. Fusionar con merge commit."`.
8. Si algo falla: no reintentes, no fuerces nada y no toques el checkout principal. Añade al final de tu respuesta `ceo-log sin publicar: <motivo>` y muestra la entrada completa para que no se pierda. Después ejecuta **Liberar el lock**.

## Liberar el lock

Último paso de toda salida posterior a la creación del lock (paso 1b): `Sin huecos`, ningún candidato, final normal, fallo de agente, fallo al publicar el log o error inesperado. Nunca se ejecuta en la salida `Dispatch en curso`: ese lock no es tuyo.

1. Desde la raíz del repo, ejecuta `rmdir "$(git rev-parse --git-common-dir)/ceo-dispatch.lock"`.
2. Si falla, no lo fuerces (nunca `rm -rf`). Añade al final de tu respuesta `Lock sin liberar: <error>` con el comando `rmdir` y la ruta absoluta (`git rev-parse --path-format=absolute --git-common-dir`) para que el dueño lo quite a mano.
