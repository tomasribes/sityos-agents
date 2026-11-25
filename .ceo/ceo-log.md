# CEO log

Append-only record of every CEO run: what was created, what was discarded and why, open questions and lessons.
Written by `/ceo-system:ceo-run` from the agent's `## Log` block. Versioned so `git log .ceo/ceo-log.md` shows the CEO's decisions over time.

### 2026-11-25 · sityos-agents · bootstrap
- Creados: ninguno (configuración inicial, sin ejecución del CEO). Proyecto Linear `Sityos Agents` (P-DEV-6) creado a mano en DEV + TOM, line `Infraestructura y tooling`, con los 7 milestones activos de `goals.md`.
- Descartados y motivo: —
- Preguntas abiertas: —
- Lecciones: no hay web pública ni CI todavía; "live" = merge en `master` con `ci.yml` en verde, que crea KR1.1. Hasta entonces los issues esperan en `Pending live`. Este repo es la fuente del propio plugin: `global/**`, los hooks y los manifiestos son human_only porque afectan a todas las sesiones y a todos los repos CEO. La adaptación del piloto en AI-Automation va en el proyecto Sityos-AI, enlazada con `blocked by`.

### 2026-11-25 · sityos-agents · live-verify
- Done: ninguno.
- Blocked y motivo: ninguno.
- Pendientes: ninguno (0 issues en `Pending live` del project Sityos Agents, team DEV).
- Lecciones: Ninguna. Nota: `live.deploy_workflow: ci.yml` aún no existe (lo crea KR1.1), así que cuando aparezcan issues en `Pending live` esperarán a ese workflow.

### 2026-11-25T19:20Z · sityos-agents
- Creados: DEV-39 (KR1.1, CI con el gate, `shellcheck -S error`, CLI fijado en 2.1.332, High) · DEV-40 (KR1.3, README de instalación por proyecto, `--plugin-dir` y ejemplo de GitHub Actions, Medium) · DEV-41 (KR1.2, catálogo alineado en 0.3.1 sin subir versión, sección `### Versiones`, Medium, blocked by DEV-39 y DEV-40 porque comparte README con DEV-40).
- Descartados y motivo: KR2.1, KR2.2, KR2.3 y KR3.1 aplazados por el tope de 3 issues por ejecución y el orden O1 > O2 > O3. KR2.1 va en el siguiente lote.
- Preguntas abiertas: ninguna.
- Lecciones: no existe el área `docs`, así que los issues de README llevan `infra`. El único rol con agente es `dev` (`dev-plugin`), por lo que la documentación también va con el rol `dev`. Los issues de este repo tocan zonas human_only casi siempre (`.github/**`, `.claude-plugin/**`): se marcan en la descripción y nunca con `needs-human`. Este agente no tiene Glob: la existencia de ficheros se comprobó con Read.

### 2026-11-25 · sityos-agents · dispatch
- Huecos: 2 (PRs abiertos 0/2 · en revisión 0/3)
- Lanzados: DEV-39 → dev-plugin · In Review · PR #6
- Lanzados: DEV-40 → dev-plugin · In Progress · PR #7
- Descartados y motivo: DEV-41 · blockedBy DEV-39 y DEV-40 (no están en Done ni en Pending live)
- Lecciones: la integración de GitHub no movió los issues a In Review al abrir el PR. DEV-39 lo movió el agente y DEV-40 sigue en In Progress con el PR abierto. El hook deny-dangerous bloqueó `gh pr create` porque el cuerpo del PR contenía la palabra «secrets» (falso positivo).

### 2026-11-25 · sityos-agents · dispatch
- Huecos: 2 (PRs abiertos 0/2 · en revisión 0/3)
- Lanzados: DEV-41 → dev-plugin · Blocked · sin PR
- Descartados y motivo: ninguno
- Lecciones: el agente bloqueó al arrancar porque el criterio 2 (tag manual en `master`) contradice un comentario del dueño sin responder (tags automáticos). El CEO debería revisar los comentarios del dueño antes de dejar un issue en Ready. Antes de despachar hubo que hacer fast-forward de `develop` en local para que el worktree incluyera los PR #6 y #7.

### 2026-11-25 · sityos-agents · dispatch
- Huecos: 2 (PRs abiertos 0/2 · en revisión 0/3)
- Lanzados: ninguno
- Descartados y motivo: DEV-41 · estado Blocked, no Ready (espera respuesta del dueño sobre el criterio del tag)
- Lecciones: Ninguna

### 2026-11-25 · sityos-agents · dispatch
- Huecos: 2 (PRs abiertos 0/2 · en revisión 0/3)
- Lanzados: ninguno
- Descartados y motivo: DEV-41 · estado Blocked, no Ready. El dueño ya respondió (opción 1, 19:37Z), pero no movió el issue a Ready.
- Lecciones: responder en el issue no lo desbloquea. Hace falta mover el estado a Ready para que el dispatcher lo coja.

### 2026-11-25 · sityos-agents · dispatch
- Huecos: 2 (PRs abiertos 0/2 · en revisión 0/3)
- Lanzados: DEV-41 → dev-plugin · In Review · PR #8
- Descartados y motivo: ninguno
- Lecciones: la integración de GitHub tampoco movió el issue al empujar la rama ni al abrir el PR; lo pasó a In Review el agente. Hay que revisar la automatización de Linear↔GitHub. Falta el issue de KR1.2 para automatizar el tag (opción 1 del dueño).

### 2026-11-25 · sityos-agents · live-verify
- Done: DEV-39, DEV-40, DEV-41. Los tres PRs (#6, #7, #8) están mergeados en develop y sus merge commits (1be4850, 6eeb3db, 559e972) están en master (compare = ahead). El run 45691884445 de ci.yml en master (c8839b5, 2026-11-25T20:07:27Z) terminó en success, con todos los steps del job `gate` en verde. Los tres issues tienen `No aplica: marketplace local`, así que bastaba con el deploy confirmado. No hay `rollback_workflow` configurado.
- Blocked y motivo: ninguno.
- Pendientes: ninguno. El tag `ceo-system-v0.3.1` lo crea el dueño en master (lo dice el comentario de DEV-41 y la subsección `### Versiones` del README). Al ser manual, el verificador no lo comprueba.
- Lecciones: `live.url` es el repo privado de GitHub y no se puede consultar con curl, pero con `No aplica` no hizo falta. `ci.yml` sale en verde sobre cualquier commit de master, así que el run valida el estado de master y no el cambio concreto de cada issue. Es una señal débil, aceptable para este repo local-tool. DEV-39 y DEV-40 siguen con los criterios de aceptación sin marcar en la descripción de Linear. No bloquea el cierre y lo marca quien implementa.

### 2026-11-25T20:13Z · sityos-agents
- Creados: DEV-42 (KR1.2, `release-tag.yml` con `workflow_run` de ci en master, comprueba que las tres versiones coincidan y nunca mueve un tag existente, Medium) · DEV-43 (KR2.1, comprueba `agent-paused` antes del verificador en ceo-run y live-verify, diagnóstico local si falta la config y deja de crear issues en TOM, Medium, blocked by DEV-42) · DEV-44 (KR2.1, quitar el commit y el push de ceo-log.md, High, `needs-human` para decidir dónde vive el log, blocked by DEV-43).
- Descartados y motivo: el resultado estructurado de KR2.1, KR2.2, KR2.3 y KR3.1, por el límite de 3 issues y el orden O1 > O2 > O3. KR2.2 sigue bloqueado por KR2.1. El siguiente lote es KR2.3, que no comparte ficheros con KR2.1, y el resultado estructurado de KR2.1.
- Preguntas abiertas: DEV-44, dónde vive el log: 1 fichero local fuera de Git (recomendado) · 2 comentarios en el project de Linear · 3 Git con un PR por ejecución.
- Lecciones: las respuestas del dueño en los comentarios de issues ya Done (DEV-41, opción 1) son trabajo pendiente y hay que buscarlas. Los issues de este repo casi siempre tocan el README, así que quedan en serie con `blocked by`; para que puedan ir en paralelo hay que meter en el mismo lote un KR que toque otros ficheros (por ejemplo KR2.3). Este agente sigue sin Glob ni Grep: la existencia de ficheros se comprobó con Read.

### 2026-11-25 · sityos-agents · dispatch
- Huecos: 2 (PRs abiertos 0/2 · en revisión 0/3)
- Lanzados: DEV-42 → dev-plugin · In Review · PR #9
- Descartados y motivo: DEV-43 · blockedBy DEV-42 (Ready) · DEV-44 · flag `needs-human` y blockedBy DEV-43
- Lecciones: la integración de GitHub sigue sin mover los issues al empujar la rama ni al abrir el PR, así que el agente los mueve a mano. Es la cuarta vez seguida.

### 2026-11-25 · sityos-agents · live-verify
- Done: DEV-42. El PR #9 está mergeado y el merge commit b3ce5df está en master. El run 45698071034 de ci.yml (4431b76) terminó en success y contiene b3ce5df. El issue dice "No aplica: marketplace local", así que bastaba con eso. Como evidencia extra, release-tag.yml ya corrió en master (run 45698117697, success) y el tag ceo-system-v0.3.1 sigue existiendo, sin moverse.
- Blocked y motivo: ninguno.
- Pendientes: ninguno.
- Lecciones: Ninguna.

### 2026-11-25 · sityos-agents · dispatch
- Huecos: 2 (PRs abiertos 0/2 · en revisión 0/3)
- Lanzados: DEV-43 → dev-plugin · In Review · PR #10
- Descartados y motivo: DEV-44 · flag `needs-human` (falta decidir dónde vive el log)
- Lecciones: la integración de GitHub sigue sin mover los issues (quinta vez). El agente detectó dos sitios fuera de alcance que no quedaron coherentes con `agent-paused`: el paso 1 de `agents/ceo.md` y la sección Kill-switches de `linear-conventions`.

### 2026-11-25 · sityos-agents · dispatch
- Huecos: 1 (PRs abiertos 1/2 · en revisión 1/3)
- Lanzados: ninguno
- Descartados y motivo: DEV-44 · blockedBy DEV-43 (In Review, PR #10 sin fusionar). Ya no tiene `needs-human`.
- Lecciones: Ninguna

### 2026-11-25 · sityos-agents · dispatch
- Huecos: 2 (PRs abiertos 0/2 · en revisión 0/3)
- Lanzados: DEV-44 → dev-plugin · Blocked · sin PR
- Descartados y motivo: ninguno
- Lecciones: el dueño eligió la opción 3 (log en Git con un PR por ejecución), pero los criterios siguen siendo los de la opción 1 y el issue volvió a Ready sin reescribirlos. Si se quita `needs-human` con una opción que cambia los criterios, el CEO tiene que reescribirlos antes de que el issue vuelva a Ready.

### 2026-11-25 · Sityos Agents · live-verify
- Done: DEV-43. Comentario de verificación publicado en el issue. No hay `rollback_workflow` configurado.
- Blocked y motivo: ninguno.
- Pendientes: ninguno.
- Lecciones: ninguna. La señal de "deploy" es ci.yml en verde sobre master, tal como declara `.ceo/config.yml`. `live.url` es un repo privado y no se comprobó con curl, porque el issue era "No aplica".

### 2026-11-25T21:10Z · sityos-agents
- Creados: DEV-45 (KR2.3, Urgent por override de seguridad). El hook normaliza las opciones globales de git (`-C`, `-c`, `--git-dir`, `--work-tree`…) antes de aplicar las reglas de push, reset, clean y branch, y añade el test de "falta jq". Toca una zona human_only. · DEV-46 (KR2.3, Medium). Lista `tools:` explícita en pm y verifier, con Bash acotado por prefijo. Antes hay que confirmar en la documentación que `tools` admite especificadores. · Actualizado DEV-44 (KR2.1, High). Reescrito para la opción 3 del dueño: worktree persistente `.claude/worktrees/ceo-log`, rama `ceo-log` con un único PR acumulado contra `develop`, dispatch que no cuenta ese PR y CEO que lee el log del worktree. Vuelve de Blocked a Proposed y queda blocked by DEV-45.
- Descartados y motivo: el resultado estructurado de KR2.1 espera a DEV-44, porque su formato depende del flujo del log. KR2.2 sigue bloqueado por KR2.1. KR3.1 se aplaza por capacidad: con DEV-44, DEV-45 y DEV-46 ya hay unas 6 h. La incoherencia de `agent-paused` que dejó DEV-43 (`agents/ceo.md` paso 1 y Kill-switches de linear-conventions) es cosmética y no la he convertido en issue.
- Preguntas abiertas: ninguna.
- Lecciones: (1) Antes de diseñar un flujo con git, revisa cómo lo interpreta el hook. Las reglas del guardarraíl empiezan en `git[[:space:]]+<subcomando>` y no ven las opciones globales, y la batería de tests no tenía ningún caso con `-C`. (2) Cuando el dueño elige una opción que cambia los criterios y deja preguntas abiertas, el CEO decide cada punto en la descripción con su motivo y lo confirma en un comentario. Si no, el agente dev vuelve a bloquear el issue. (3) El CEO no tiene Bash, así que cualquier dato que tenga que leer (como el log sin fusionar) tiene que estar en una ruta de disco, no solo en una rama remota.

### 2026-11-25 · sityos-agents · dispatch
- Huecos: 2 (PRs abiertos 0/2 · en revisión 0/3)
- Lanzados: DEV-45 → dev-plugin · In Review · PR #11
- Lanzados: DEV-46 → dev-plugin · Blocked · sin PR
- Descartados y motivo: DEV-44 · blockedBy DEV-45 (Ready, aún no está en Done ni en Pending live)
- Lecciones: DEV-46 se bloqueó porque la documentación de subagentes no admite `Bash(prefijo:*)` en `tools`: el CEO dio por buena una sintaxis sin verificarla. DEV-45 dejó fuera algunas opciones globales de git (`--exec-path`, `--config-env`…). La integración de GitHub sigue sin mover los issues.

### 2026-11-25 · sityos-agents · live-verify
- Done: ninguno.
- Blocked y motivo: ninguno.
- Pendientes: DEV-45 sigue en Pending live, sin comentario en Linear. Esperando el merge develop→master y un run correcto de `ci.yml` en `master`. No he comprobado deploy ni checks en vivo, porque el commit no ha llegado a `master`. El issue declara `No aplica: marketplace local`, así que cuando llegue a `master` bastará con un run `success` de `ci.yml` cuyo `headSha` contenga 13c93cb.
- Lecciones: Ninguna.

### 2026-11-25T21:33Z · sityos-agents
- Creados: DEV-47 (KR2.3, Urgent por override de seguridad). Se añade una regla de cierre en el hook: si después de normalizar la llamada a git sigue empezando por `git -…` y el mismo segmento contiene push, reset, clean o branch, se bloquea. Añade 7 casos al test y una frase en `### Guardarraíl` del README. Es related de DEV-45 y DEV-44. · DEV-48 (KR3.1, Medium). Crea `AGENTS.md` (≤ 150 líneas: componentes, gate, never_run, ramas y zonas por remisión) y `CLAUDE.md` (≤ 40 líneas: `@AGENTS.md`, `--plugin-dir`, versión, puntos de entrada). · Actualizado DEV-46 (KR2.3, Medium). Reescrito para la opción 2 del dueño: `tools` con Bash entero y una lista cerrada de herramientas Linear y Chrome por agente. Pasa de Blocked a Proposed y lleva un comentario de confirmación.
- Descartados y motivo: el resultado estructurado de KR2.1 y el issue de KR2.2 esperan a DEV-44 (flujo del log y `dispatch.md`). La incoherencia de `agent-paused` en `agents/ceo.md` y en linear-conventions sigue siendo cosmética y no he creado issue.
- Preguntas abiertas: ninguna.
- Lecciones: (1) Una lista cerrada de excepciones en un guardarraíl de regex siempre deja huecos. Hay que preferir reglas que fallen cerradas ante lo que no se reconoce. (2) Antes de fijar una sintaxis de frontmatter en los criterios, hay que citar la documentación (DEV-46 se bloqueó por `Bash(prefijo:*)`). (3) Los issues del README pueden ir en paralelo si cada uno declara la sección exacta que toca. (4) Sin Glob ni Grep, la existencia de ficheros se sigue comprobando con Read.

### 2026-11-25 · sityos-agents · live-verify
- Done: DEV-45. El PR #11 se fusionó en develop con el commit 13c93cb. master lo contiene (compare = ahead). El run 45705601628 de ci.yml sobre master (383a9ec, job `gate` en success) lo incluye. La sección `## Verificación en producción` dice "No aplica: marketplace local", así que bastó con confirmar el deploy.
- Blocked y motivo: ninguno.
- Pendientes: ninguno.
- Lecciones: ninguna. `live.url` es el repo privado de GitHub y no se puede consultar con curl. Todos los issues de este proyecto deben llevar "No aplica". Config sin `rollback_workflow`, así que no se comprobó ningún rollback.

### 2026-11-25 · sityos-agents · dispatch
- Huecos: 2 (PRs abiertos 0/2 · en revisión 0/3)
- Lanzados: DEV-47 → dev-plugin · In Review · PR #12
- Lanzados: DEV-44 → dev-plugin · In Progress · PR #13
- Descartados y motivo: DEV-46 · sin hueco · DEV-48 · sin hueco
- Lecciones: la integración de GitHub sigue sin mover los issues: DEV-44 se queda en In Progress con el PR abierto. Los PR #12 y #13 tocan secciones distintas del README. Es la última entrada que se commitea en develop: cuando se fusione el PR #13, el log pasa a la rama `ceo-log`.

### 2026-11-25 · sityos-agents · live-verify
- Done: DEV-44 y DEV-47. Ambos PR están mergeados en develop y sus merge commits son ancestros de master (compare = ahead). El run 45707888759 de ci.yml en master (headSha 4b80721, 2026-11-25T21:49:51Z, success) es el primero que contiene ambos commits. Los dos issues tienen "No aplica: marketplace local" en su sección de verificación, así que con el deploy confirmado bastaba. No hay rollback_workflow configurado.
- Blocked y motivo: ninguno.
- Pendientes: ninguno.
- Lecciones: Ninguna. Una nota menor: el campo `live.url` apunta a un repo privado y no se puede comprobar con curl. Esto no afecta mientras los issues sean "No aplica".
