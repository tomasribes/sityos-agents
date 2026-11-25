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
