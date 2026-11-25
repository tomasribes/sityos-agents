# goals.md — sityos-agents

> Objetivos priorizados para **2026-11-26 → 2026-12-31** (5 semanas).
> Fuente de verdad del **agente CEO**, que los convierte en trabajo en Linear.
>
> **Dueño:** propietario del proyecto · **Última revisión:** 2026-11-25
> **Relacionado:** [`README.md`](README.md) · [`.ceo/config.yml`](.ceo/config.yml) (contrato CEO) · [Auditoría de arquitectura 2026-11-25](docs/audits/2026-11-25-arquitectura-claude-code.md) (origen de todos los KR)

---

## 1. Instrucciones para el agente CEO

### Mapeo a Linear

| goals.md | Entidad Linear | Nombre |
|---|---|---|
| Fichero completo | **Project** `Sityos Agents` (P-DEV-6; equipo DEV para código, TOM para tareas del dueño) | — |
| Objetivo (`O1`…`O4`) | **Label** del grupo `goal` (`O1`…`O4`) | — |
| Key Result (`KR1.1`…) | **Milestone** dentro de `Sityos Agents` | `KR1.1 — CI del marketplace` |
| Tarea derivada de un KR | **Issue** dentro del milestone | Verbo en imperativo, ≤ 80 caracteres |

### Active milestones

El CEO crea issues **solo** en estos milestones. El resto espera al siguiente periodo.

- `KR1.1 — CI del marketplace` (primero: es la señal "live" del verificador)
- `KR1.2 — Versión explícita`
- `KR1.3 — Instalación por proyecto`
- `KR2.1 — Log fuera de la rama base`
- `KR2.2 — Dispatch serial e idempotente`
- `KR2.3 — Herramientas mínimas`
- `KR3.1 — Instrucciones de raíz`

### Reglas de planificación

1. **Orden de prioridad estricto:** O1 > O2 > O3 > O4. Dentro de un objetivo, los KR van en orden de prioridad.
2. **Capacidad:** 1 persona + agentes, **~5 h/semana (~25 h en el periodo)**. No planifiques más.

   | Objetivo | Reparto | ~Horas / periodo |
   |---|---|---|
   | O1 — Publicación fiable | 40 % | 10 h |
   | O2 — Contratos CEO comprobables | 40 % | 10 h |
   | O3 — Arquitectura de instrucciones | 15 % | 4 h |
   | O4 — Calidad y optimización | 5 % | 1 h |

3. **Tamaño de issue:** ≤ 3 h. Parte lo que sea mayor.
4. **Override de seguridad:** un fallo del guardarraíl (`deny-dangerous.sh` deja pasar algo que debía bloquear) o un secreto expuesto **gana a cualquier prioridad**. Issue `Urgent`, fusionado en **48 h**.
5. **Dependencias (block/blocked-by en Linear):**
   - `KR1.2` está bloqueado por `KR1.1` (el tag se publica con CI en verde).
   - `KR2.2` está bloqueado por `KR2.1` (ambos tocan `commands/dispatch.md`).
   - `KR2.4` (siguiente periodo) está bloqueado por `KR2.1`. Su adaptación en AI-Automation es un issue del proyecto **Sityos-AI** con `blocked by` al issue de este proyecto.
   - Dos issues que tocan el mismo fichero de `plugins/ceo-system/` se encadenan con `blocked by`.
6. **Definition of Done (cada issue):**
   - Gate en verde en local (`gate.commands` de `.ceo/config.yml`): `bash -n`, test del hook, `claude plugin validate --strict` del marketplace y del plugin.
   - Un cambio en el hook añade sus casos a `plugins/ceo-system/tests/deny-dangerous.test.sh`.
   - Un cambio de comportamiento del plugin actualiza el README en un commit aparte del mismo PR.
   - PR fusionado en `develop`. Los agentes nunca fusionan a `master`: `develop` → `master` es del dueño, y un run verde de `ci.yml` en `master` que contiene el merge es lo que el verificador trata como "live". Los issues llevan `## Verificación en producción · No aplica: marketplace local`.
7. **El repo es la fuente del propio plugin.** Ningún agente instala, actualiza ni recarga plugins o MCP en la máquina del dueño, ni ejecuta `install-sityos-agents.sh` (ver `gate.never_run`). Las pruebas usan `claude --plugin-dir ./plugins/ceo-system` o validación estática.
8. **Zonas `human_only`:** `global/**` (afecta a todas las sesiones), hooks, manifiestos y versiones, instalador. Un issue puede proponer el cambio; lo revisa y fusiona el dueño.
9. **Fuera de este repo:** cambios en repos consumidores (`.ceo/config.yml`, `.claude/agents/`) se crean en el proyecto Linear de ese repo, nunca aquí.
10. **Labels:** uno por grupo — `goal` (O1–O4) · `type` (Bug · Feature · Improvement · Maintenance) · `role` · `risk` · `auto`; uno o dos de `area` (`infra` para CI/instalador/hooks, `backend` para comandos y agentes del plugin, `docs` cuando exista).
11. **Fechas de milestone:** las de la tabla de cada KR; si no hay, 2026-12-31.

---

## 2. Línea base (2026-11-25)

| Área | Estado actual |
|---|---|
| Componentes | `global/CLAUDE.md` (275 líneas, symlink a `~/.claude/CLAUDE.md`) · 4 skills `agents/sityos-*` · plugin `ceo-system` (3 agentes, 4 comandos, 2 skills, 1 hook) · `project-override/` (plantilla Drupal) |
| Versiones | `plugin.json` 0.3.1 · `marketplace.json` plugin 0.3.1 / catálogo 0.1.0 · instalado en usuario: 0.2.0 · sin tags |
| Calidad | `claude plugin validate --strict` en verde · 44 aserciones del hook en verde · **sin CI** · sin shellcheck |
| Instrucciones del repo | Sin `AGENTS.md` ni `CLAUDE.md` de raíz · `.gitignore` excluía `/.claude/` entero (corregido en el bootstrap) |
| Ciclo CEO | `ceo-log.md` se commitea y pushea a `develop` sin PR · dispatch sin exclusión entre ejecuciones · PM y verificador heredan Bash · verificación por "run más antiguo con el commit" |
| Consumidores | AI-Automation (piloto), finanzas-mcp, job-finder, agencia-ia-trt · roles referenciados que no existen (`ceo-system:review-code`, `ceo-system:docs`, `ceo-system:content`) |
| Instalador | Modifica el perfil antes de validar el destino · MCP finanzas y DigitalOcean en todos los proyectos · `npx` sin versiones fijadas |

---

## 3. Objetivos y Key Results

### O1 — Publicación fiable · **P1**

**Por qué:** hoy hay tres versiones del plugin en circulación y nada impide publicar una que rompa el hook. Un clon limpio debe resolver la misma versión y los mismos puntos de entrada. (Auditoría §2, fase 1.)

| KR | Objetivo | Fecha | Medido con |
|---|---|---|---|
| **KR1.1 — CI del marketplace** | `.github/workflows/ci.yml` en push y PR a `develop` y `master`: `bash -n`, test del hook, `claude plugin validate --strict` (marketplace y plugin), shellcheck sin errores · run verde en `master` | 2026-12-05 | GitHub Actions |
| **KR1.2 — Versión explícita** | `marketplace.json` y `plugin.json` con la misma versión · tag `ceo-system-vX.Y.Z` en `master` · README documenta la ref de distribución y cómo ver qué versión carga Claude (`claude plugin list`) | 2026-12-12 | Tag · README |
| **KR1.3 — Instalación por proyecto** | README con la instalación de consumidor: `extraKnownMarketplaces` + `enabledPlugins` en `.claude/settings.json`, `claude plugin install ceo-system@sityos-agents --scope project`, `claude --plugin-dir` para desarrollo · ejemplo de GitHub Actions con la forma de terminal (no `/plugin`) | 2026-12-12 | Review |
| KR1.4 — Instalador con preflight *(siguiente periodo)* | Valida destino y colisiones antes de escribir · escritura atómica de `settings.json` · versiones `npx` fijadas · MCP operativos solo por proyecto · separa bootstrap de proyecto y preferencias personales | — | Prueba en entorno aislado |

**Notas de alcance:**
- **KR1.1:** el CLI de Claude se instala en el runner con versión fijada. Si `claude plugin validate` necesita autenticación, el issue lo comprueba primero y lo escala al dueño.
- **KR1.2:** `.claude-plugin/**` es human_only: el PR lo revisa el dueño, y el tag lo crea el dueño tras el merge a `master`.

---

### O2 — Contratos CEO comprobables · **P1**

**Por qué:** los límites de ejecución, el aislamiento y la evidencia de despliegue dependen de instrucciones que el modelo interpreta. Los fallos de prioridad alta de la auditoría (§3) pueden pushear commits ajenos a `develop` o duplicar trabajo. (Fase 2.)

| KR | Objetivo | Fecha | Medido con |
|---|---|---|---|
| **KR2.1 — Log fuera de la rama base** | `ceo-run`, `dispatch` y `live-verify` no hacen commit ni push a `branches.base` · cada ejecución produce un resultado estructurado (ID, versión del plugin, repo, acciones, errores) · el preflight comprueba `.ceo/PAUSE` y `agent-paused` antes de lanzar el verificador · repo sin `goals.md`/`.ceo/config.yml` → diagnóstico local, sin crear issues en TOM | 2026-12-19 | Revisión de comandos · ejecución en seco |
| **KR2.2 — Dispatch serial e idempotente** | Lock por proyecto (dos `dispatch` simultáneos: el segundo sale sin efectos) · re-lectura del estado del issue justo antes de lanzar · base SHA de `origin/<base>` fijada y comprobada en el worktree · un candidato que ya no está en *Ready* queda intacto | 2026-12-31 | Escenario documentado en el PR |
| **KR2.3 — Herramientas mínimas** | `pm` y `verifier` con `tools:` explícitos (allowlist) en vez de `disallowedTools` · sin Bash de escritura · el hook tiene test del caso "falta `jq`" (falla cerrado) | 2026-12-31 | Frontmatter · test del hook |
| KR2.4 — Verificación por artefacto activo *(siguiente)* | Modos `live-http` / `ci-only` / `manual` en `live` · evidencia = artefacto, SHA, entorno y checks · campo de resultado FAIL estable compartido por CEO y verificador | — | Fixtures |
| KR2.5 — Esquema y doctor *(siguiente)* | Esquema de `.ceo/config.yml` versionado · `/ceo-system:doctor` de solo lectura que resuelve roles, herramientas, rama base y estados · semántica de L0–L2 (qué autoriza pasar a *Ready*, qué transiciones exigen revisión) | — | Doctor en los 4 consumidores |

**Notas de alcance:**
- **KR2.1:** el registro sale de Git (artefacto o fichero no versionado). Si el dueño quiere persistencia en Git, el issue lo pregunta (`needs-human`) en vez de decidirlo.
- **KR2.2:** el paralelismo entre worktrees queda fuera (fase 4): el objetivo es serializar, no paralelizar.
- **KR2.3:** los agentes de plugin ignoran `hooks`, `mcpServers` y `permissionMode` del frontmatter; no los uses como control.

---

### O3 — Arquitectura de instrucciones · **P2**

**Por qué:** el global mezcla preferencias, inventario, marca, estándares y procedimiento CEO, y el repo del marketplace no explica cómo mantenerse a sí mismo. (Auditoría §1–2.)

| KR | Objetivo | Fecha | Medido con |
|---|---|---|---|
| **KR3.1 — Instrucciones de raíz** | `AGENTS.md` de raíz (componentes, responsabilidad de cada uno, comandos de comprobación) · `CLAUDE.md` que importa `@AGENTS.md` y añade cómo cargar el plugin local, comprobar la versión y probar los puntos de entrada | 2026-12-31 | Review |
| KR3.2 — Global < 200 líneas *(siguiente)* | `global/CLAUDE.md` solo con preferencias estables · inventario de proyectos, marca y estándares por lenguaje en referencias o `.claude/rules/` con `paths` | — | `wc -l` |
| KR3.3 — Plantilla de proyecto *(siguiente)* | `project-override/` → plantilla mínima sin DDEV ni `web/`, que importa `AGENTS.md` · `drupal-module` parametriza la versión de Drupal · `content-page` parametriza idiomas | — | Review |
| KR3.4 — Skills con namespace *(siguiente)* | `agents/sityos-*` migran a un plugin opcional `sityos-skills` · descripciones con condiciones de activación concretas · tokens frontend alineados con `--sao-*` · `ceo-run`/`dispatch`/`live-verify` como skills con `disable-model-invocation: true`, sin cambiar `/ceo-system:<nombre>` | — | `plugin validate` |

---

### O4 — Calidad y optimización · **P3**

**Por qué:** las rutas que escriben en Linear y GitHub solo se han revisado por inspección. Y cada sesión paga el contexto del global y de las skills precargadas.

| KR | Objetivo | Fecha | Medido con |
|---|---|---|---|
| KR4.1 — Evals del plugin *(siguiente)* | Evals con MCP simulado y fixtures: reserva caducada, rol ausente, pausa, rollback, selección de artefacto | — | `claude plugin eval` |
| KR4.2 — Coste de contexto *(siguiente)* | Medir tokens cargados al arrancar (global + skills precargadas en agentes) y fijar un presupuesto por sesión | — | Informe |

---

## 4. Fuera de alcance (este periodo)

- Paralelismo en `dispatch` y entornos Compose por worktree (fase 4 de la auditoría).
- Activar un segundo consumidor en modo CI (fase 3).
- Cambios en repos consumidores desde este proyecto (van al proyecto Linear de cada repo).
- Nuevos agentes por skill: la delegación solo se justifica con permisos distintos, contexto aislado o trabajo independiente.

---

## 5. Revisión

- **Cada semana:** status update en el proyecto Linear con el avance de los KR activos.
- **Fin de periodo (2026-12-31):** puntuar cada KR (0–100 %), actualizar la **Línea base** y activar los KR marcados *(siguiente)* que correspondan.
