# Batería de agentes

Qué agentes son globales (plugin `ceo-system`), cuáles se quedan en cada repo y cómo
encajan con los roles de la plataforma TAIS (`trt-ai-platform`,
*AI Engineering Platform v1.0*). Decisión tomada el 2026-11-26 tras validar las
integraciones con AI-Automation, job-finder, agencia-ia-trt, finanzas-mcp y este repo.

## Criterio

Se globaliza lo que es **igual en todos los repos** y se deja local lo que **solo tiene
sentido con el código del repo delante**.

| Qué | Dónde | Por qué |
|---|---|---|
| Protocolo del developer (arranque, rama desde la base fijada, zonas, gate, commits, PR, respuesta) | Skill `ceo-system:dev-protocol` | ~70 % de los cinco `dev-*` era el mismo texto, copiado a mano y ya desfasado |
| Zonas, gate y `never_run` | Solo `.ceo/config.yml` | Copiarlos en el prompt los desincronizó: `dev-typescript` decía "`npm test` cuando exista" con `npm test` ya en el gate |
| Entorno y normas del stack (`.venv`, `npm ci`, Drupal en Docker…) | Agente `dev-*` del repo, reducido | Es lo único que cambia entre repos |
| Revisión independiente de PRs | Agente `ceo-system:review-code` + comando `/ceo-system:review` | Rol `reviewer` ya referenciado en cuatro `config.yml` sin agente que lo cubriera |
| Agentes de dominio (`watchlist-curator`, `scoring-calibrator`…) | Repo | No se reutilizan en otro proyecto |
| Espejo Codex (`.codex/agents/*.toml`) | Generado con `tools/sync-codex-agents.sh` | Mantenido a mano, los 8 espejos existentes se habían desviado de su fuente |

**Rendimiento.** Un agente del plugin corre en su propio contexto, igual que uno local.
La skill se precarga con `skills:` en el frontmatter, como ya se hace con
`linear-conventions` y `pr-contract`: no añade llamadas. El prompt total del developer
no crece; el fichero local pasa de ~60–95 líneas a ~15–25.

**Versionado.** Un repo recibe un cambio del protocolo solo cuando sube el `ref` de su
`.claude/settings.json` a un tag nuevo, con un PR revisable. Nunca le llega en caliente.

## Roles y su correspondencia con TAIS

TAIS define roles independientes del proveedor (§07) y un protocolo de revisión ligado
a SHA (§11). La batería usa los mismos nombres de rol y el mismo nivel de acceso, para
que TAIS pueda registrarla como `config/agents` cuando exista el plano de control, sin
reescribir los prompts.

| Rol TAIS | Acceso | Proveedor preferido (TAIS) | Agente hoy | Label `role` |
|---|---|---|---|---|
| architect | solo lectura | Codex | `ceo-system:ceo` (planifica, no escribe código) | — |
| developer | escritura en worktree | Claude | `dev-*` del repo + `ceo-system:dev-protocol` | `dev` |
| reviewer | solo lectura | Codex | `ceo-system:review-code` | `reviewer` |
| QA / tester | escritura en worktree | Claude | pendiente (`tester-*` en varios `config.yml`) | `tester` |
| knowledge | solo lectura | modelo local | — (llega con TAIS M2) | — |
| verificador live | solo lectura | Claude | `ceo-system:verifier` | — |
| digest | solo lectura | Claude | `ceo-system:pm` | `pm` |

Lo que ya cumple del contrato de TAIS:
- **Base fijada y SHA en las revisiones** (§11, §17): el dispatcher fija `BASE_SHA` y
  comprueba las ramas. `review-code` revisa un `Head` concreto y lo deja escrito.
- **Nadie aprueba sus propios cambios** (§11): `review-code` es otro agente, no usa
  `--approve` y la fusión es siempre del dueño.
- **Hallazgos verificados** contra ruta y línea reales, con severidad y evidencia (§11, §16).
- **Sin despliegues ni merges desatendidos** (§02, §18): guardarraíl `deny-dangerous.sh`.

Lo que falta y es trabajo de TAIS, no de este plugin: cola durable y leases, ejecución
del revisor con Codex (`codex exec --sandbox read-only`), evidencia con hash, aprobación
ligada al SHA final y bucle de remediación con máximo 2 rondas.

**Dónde vive la batería.** En este repo mientras TAIS no tenga plano de control: un
repo vacío no puede ejecutar agentes, y tenerlos en dos sitios partiría la fuente de
verdad. Cuando TAIS llegue a su Milestone 1, importará los roles de aquí.

## Plantilla del developer reducido

`.claude/agents/dev-<stack>.md` en el repo consumidor, con el plugin fijado a una
versión que incluya `ceo-system:dev-protocol` (≥ 0.5.0):

```markdown
---
name: dev-<stack>
description: CEO-system dev agent for <repo>. Implements exactly one Ready Linear issue (role label `dev`) following ceo-system:dev-protocol and opens a PR against develop. Use when the dispatcher or the owner assigns a DEV issue to implement.
tools: Read, Edit, Write, Bash, Grep, Glob, Skill, mcp__claude_ai_Linear__get_issue, mcp__claude_ai_Linear__list_comments, mcp__claude_ai_Linear__save_comment, mcp__claude_ai_Linear__save_issue
skills: ceo-system:dev-protocol, ceo-system:linear-conventions, ceo-system:pr-contract
---

Eres el developer de <repo>. Sigue `ceo-system:dev-protocol` paso a paso; aquí solo
está lo propio de este repo.

## Entorno
- <cómo preparar el entorno dentro del worktree>

## Normas del stack
- <normas que no estén ya en AGENTS.md; si lo están, remite a AGENTS.md>

## Condiciones de parada extra
- <p. ej. criterios que solo se verifican con datos reales o credenciales>

## Resumen del gate
`<cmd> ✓ · <cmd> ✓`
```

No copies zonas, gate ni `never_run`: el protocolo los lee de `.ceo/config.yml`.

## Espejo Codex

```bash
bash ~/ai-projects/sityos-agents/tools/sync-codex-agents.sh <repo>          # regenera .codex/agents/
bash ~/ai-projects/sityos-agents/tools/sync-codex-agents.sh --check <repo>  # exit 1 si hay desfase
```

El `.toml` lleva `name`, `description` y `developer_instructions` (el cuerpo Markdown tal
cual). El cambio de un agente y su `.toml` regenerado van en el mismo PR. Qué partes del
plugin funcionan en Codex: [`docs/compat/codex.md`](compat/codex.md).
