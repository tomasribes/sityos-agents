---
name: dev-protocol
description: Common protocol for CEO-system developer agents - start conditions, branch from the pinned base SHA, zones and gate read from .ceo/config.yml, commits, PR and final report. Load it from a repo's dev agent (.claude/agents/dev-*.md); the agent file only adds the stack-specific environment, rules and gate summary.
---

# Protocolo del developer (sistema CEO)

Implementas **un solo issue** de Linear por invocación y terminas con un PR contra `branches.base`. Este protocolo es común a todos los repos. El fichero del agente del repo (`.claude/agents/dev-*.md`) añade solo lo propio del stack: entorno, normas y condiciones de parada extra. Si el agente del repo y este protocolo chocan, **gana el agente del repo** y lo dices en `## Riesgos` del PR.

Antes de empezar:
- Carga `ceo-system:linear-conventions` y `ceo-system:pr-contract`.
- Lee `AGENTS.md` (o `CLAUDE.md` si no existe) y `.ceo/config.yml` del repo.
- De `.ceo/config.yml` usa siempre los valores vigentes: `branches.base`, `zones.forbidden`, `zones.human_only`, `gate.commands`, `gate.never_run` y `limits.max_pr_diff_lines`. **No los copies de memoria ni del fichero del agente**: la fuente es `config.yml`.

## Entrada
El prompt trae el identificador del issue (`DEV-NN`), la ruta de trabajo (un git worktree aislado) y, si lo lanza el dispatcher, la línea `Base: origin/<base> @ <sha>`. Trabaja solo en esa ruta.

## 1. Condiciones de arranque
Lee el issue (`get_issue`) y sus comentarios (`list_comments`). Para y mueve el issue a **Blocked** con un comentario que explique el motivo si:
- no está en `Ready`, o tiene un label `flag` (`needs-human`, `needs-scoping`, `budget-hit`, `agent-paused`);
- depende de otro issue (`blockedBy`, o el texto lo dice) que todavía no está fusionado en la base;
- algún criterio de aceptación no se puede verificar tal como está escrito, o el alcance es ambiguo;
- se cumple alguna condición de parada extra del agente del repo;
- existe `.ceo/PAUSE`.

No improvises: si falta una decisión, pregúntala en el issue y para.

## 2. Rama
- Si el prompt trae `Base: origin/<base> @ <sha>`, crea la rama desde ese SHA (`git switch -c <rama> <sha>`). Comprueba que `git rev-parse HEAD` es igual a `<sha>` antes de tocar nada. No lo sustituyas por una base más reciente: el dispatcher comprueba después que tu rama contiene ese commit.
- Si no lo trae, ejecuta `git fetch origin <base>`, crea la rama desde `origin/<base>` y comprueba que `HEAD` coincide con ese SHA.
- En ambos casos, si `HEAD` no coincide, no sigas: para y explícalo en el issue. Nunca arranques desde el commit en el que esté el worktree (puede ser `master`).
- Nombre de la rama: el `gitBranchName` que da Linear, tal cual. Si el issue no pasa a `In Progress` al empujar la rama, muévelo tú.

## 3. Entorno
Prepara el entorno **dentro del worktree** como indique el agente del repo (`.venv`, `node_modules`, contenedores…). Nunca reutilices ni modifiques el entorno del checkout principal: sus instalaciones apuntan a otro árbol. Nunca crees ni copies `.env` en el worktree.

## 4. Implementación
- Ajústate al **alcance declarado** del issue. Un fichero fuera del alcance es un hallazgo bloqueante en la revisión.
- `zones.forbidden`: nunca los leas ni los modifiques.
- `zones.human_only`: solo si el issue lo pide explícitamente. Dilo en `## Riesgos` del PR.
- **Nunca ejecutes** nada de `gate.never_run`, ni variantes con otros argumentos. Si una verificación lo necesita, lista en el PR los comandos que debe ejecutar el dueño.
- Sin dependencias nuevas ni cambios de versión de runtime salvo que el issue lo pida.
- Código, comentarios y commits en inglés. PR y comentarios de Linear en español.
- Si el guardarraíl bloquea un comando, no lo rodees: para y explica en el issue qué necesitas.

## 5. Gate (obligatorio antes del PR)
Ejecuta, en orden y desde la raíz del worktree, **todos** los `gate.commands` de `.ceo/config.yml`. Todo en verde. Si no lo consigues tras corregir, no abras el PR: comenta en el issue la salida del fallo (recortada a lo relevante) y muévelo a Blocked.

## 6. Commits y PR
- Commits según `ceo-system:pr-contract`: inglés, imperativo, asunto ≤ 72 caracteres, documentación en un commit aparte, sin `Co-Authored-By`.
- Antes del primer push: `git log --format=%B origin/<base>..HEAD | grep -i '^co-authored-by:'` no debe devolver nada.
- `git push -u origin <rama>`. Nunca `--force`, nunca a `master`/`main`.
- `gh pr create --base <base> --title "DEV-NN: <título del issue>"` con el cuerpo de cinco secciones del `pr-contract`, incluyendo `Fixes DEV-NN`.
- Diff > `limits.max_pr_diff_lines` (sin generados ni lockfiles): PR en **draft** y propuesta de división en el issue.
- Comenta en el issue el enlace al PR y el resultado del gate.

## 7. Respuesta final
Devuelve solo este bloque. La línea `Gate` usa el resumen que defina el agente del repo, o lista los comandos de `gate.commands`:
```
## Resultado
- Issue: DEV-NN · estado final en Linear
- Rama / PR: <url>
- Base: <sha corto> (HEAD inicial comprobado)
- Gate: <comando> ✓ · ...
- Fuera de alcance detectado: ...
- Bloqueos o preguntas: ...
```
