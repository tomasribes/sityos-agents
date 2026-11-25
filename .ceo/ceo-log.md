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
