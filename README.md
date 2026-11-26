# SITYOS Agent System

Sistema de agentes y skills para el ecosistema **SITYOS AI / Sityos Automate**.

## Estructura

```
sityos-agents/
├── install-sityos-agents.sh        ← Script de instalación
├── global/
│   └── CLAUDE.md                   → ~/.claude/CLAUDE.md (symlink, --link-claude-md)
├── agents/                         (symlinks, se editan aquí y aplican al instante)
│   ├── sityos-frontend/SKILL.md    → ~/.claude/skills/sityos-frontend
│   ├── sityos-drupal/SKILL.md      → ~/.claude/skills/sityos-drupal
│   ├── sityos-devops/SKILL.md      → ~/.claude/skills/sityos-devops
│   └── sityos-content/SKILL.md     → ~/.claude/skills/sityos-content
└── project-override/
    ├── CLAUDE.md                   → <proyecto>/CLAUDE.md (p.ej. ~/ai-projects/AI-Automation)
    └── .claude/commands/
        ├── drupal-module.md        → /drupal-module <nombre>
        └── content-page.md        → /content-page <tipo> <tema>
```

## Instalación rápida

```bash
bash install-sityos-agents.sh                    # skills + MCP de usuario + attribution.commit="" (sin Co-Authored-By)
bash install-sityos-agents.sh --project <ruta>   # + override de proyecto
bash install-sityos-agents.sh --link-claude-md   # + symlink del CLAUDE.md global
```

MCP compartidos (scope `user`, visibles en todos los proyectos): se registran en la
sección 2 del script (`register_mcp`). Secretos siempre vía `${VAR}`, nunca inline.

## Arquitectura de dos niveles

### Global (`~/.claude/`)
Aplica a **todas las sesiones** de Claude Code. `global/CLAUDE.md` es la fuente de verdad
de `~/.claude/CLAUDE.md` una vez enlazado con `--link-claude-md`. Contiene:
- Rol, contexto operativo y proyectos activos
- Brand context de Sityos y tabla de skills `sityos-*`
- Estándares de código, comportamiento y formato de respuesta
- Convenciones de proyecto (`AGENTS.md` canónico), índice de `~/ai-projects` y sistema CEO

### Proyecto (`<proyecto>/CLAUDE.md`)
Override que aplica **solo dentro de ese directorio**. Contiene:
- Stack específico del proyecto
- Variables de entorno requeridas
- Comandos frecuentes
- Decisiones de arquitectura

## Uso de los skills en Claude Code

Se activan solos según su `description`, o explícitamente:

```bash
/sityos-frontend   → UI, React, brand assets, theme SCSS
/sityos-drupal     → Backend PHP, módulos, Twig
/sityos-devops     → DigitalOcean, Docker, CI/CD, MCP
/sityos-content    → Copy, SEO, documentos cliente

# Slash commands del proyecto
/drupal-module <nombre>      → Scaffolding módulo Drupal
/content-page <tipo> <tema>  → Copy trilingual ES/EN/CA
```

## Skills globales

| Skill | Propósito | Origen |
|-------|-----------|--------|
| `sityos-frontend` | Agente frontend | este repo (script) |
| `sityos-drupal` | Agente Drupal | este repo (script) |
| `sityos-devops` | Agente DevOps | este repo (script) |
| `sityos-content` | Agente Content | este repo (script) |
| `frontend-design` | UI production-grade | externo (`~/.agents/skills`) |
| `find-skills` | Autodescubrimiento de skills | externo (`~/.agents/skills`) |
| `impeccable` | Quality gate de UI | externo (`~/.agents/skills`) |
| `llm-council` | Revisión multi-modelo | externo |

## Git

`.gitignore` excluye ficheros locales de Claude Code (`/.claude/`, `CLAUDE.local.md`),
estado local de runtime (`.mcp.json`, `*.db`),
backups del script (`*.backup.*`), `.DS_Store` y secretos. `project-override/.claude/`
sí se versiona (el patrón `/.claude/` solo aplica a la raíz).

## Actualizar un agente

```bash
# Editar agents/<nombre>/SKILL.md — al ser symlink no hace falta reinstalar.
# Para un agente nuevo: crear agents/<nombre>/SKILL.md y volver a ejecutar el script.
```

## Plugin `ceo-system` (Sistema CEO-Agente)

Este repo es también un **marketplace de plugins** de Claude Code. El plugin
`ceo-system` convierte el `goals.md` de cada repo en issues de Linear y,
en fases posteriores, en PRs revisables. Convive con las skills `sityos-*`:
el script de instalación no se ve afectado.

```
.claude-plugin/marketplace.json        ← marketplace "sityos-agents"
plugins/ceo-system/
├── .claude-plugin/plugin.json
├── agents/
│   ├── ceo.md                         → ceo-system:ceo       (planifica, sin escritura)
│   ├── verifier.md                    → ceo-system:verifier  (cierra issues tras verificar en producción)
│   ├── pm.md                          → ceo-system:pm        (digest diario, solo lectura)
│   └── review-code.md                 → ceo-system:review-code (revisión independiente de un PR, solo lectura)
├── commands/
│   ├── ceo-run.md                     → /ceo-system:ceo-run      (goals.md → issues en Proposed)
│   ├── dispatch.md                    → /ceo-system:dispatch     (issues Ready → agentes → PRs)
│   ├── live-verify.md                 → /ceo-system:live-verify  (Pending live → Done/Blocked)
│   ├── pm-digest.md                   → /ceo-system:pm-digest
│   └── review.md                      → /ceo-system:review       (PRs en In Review → revisor)
├── skills/
│   ├── linear-conventions/SKILL.md    estados, labels, transiciones, contrato de issue
│   ├── pr-contract/SKILL.md           formato y límites de PR
│   └── dev-protocol/SKILL.md          protocolo común de los agentes dev-* de los repos
├── hooks/
│   ├── hooks.json                     PreToolUse sobre Bash y herramientas de ficheros
│   └── deny-dangerous.sh              guardarraíl (falla cerrado)
└── tests/deny-dangerous.test.sh       batería de casos del guardarraíl
```

### Instalación

El plugin se habilita **por proyecto**, nunca en ámbito de usuario: su hook
`PreToolUse` se ejecuta en todas las sesiones donde el plugin está habilitado.

#### Repo consumidor

1. Declara el marketplace y habilita el plugin en el `.claude/settings.json`
   del repo (se commitea):

   ```json
   {
     "extraKnownMarketplaces": {
       "sityos-agents": {
         "source": {
           "source": "github",
           "repo": "tomasribes/sityos-agents"
         }
       }
     },
     "enabledPlugins": {
       "ceo-system@sityos-agents": true
     }
   }
   ```

2. Una vez por clon, descarga el plugin en ámbito de proyecto (el
   `settings.json` lo habilita, pero no lo instala):

   ```bash
   claude plugin install ceo-system@sityos-agents --scope project
   ```

El repo es privado: Claude Code clona el marketplace con las credenciales git
que ya tenga la máquina (`gh auth login`, clave SSH sin passphrase) y nunca
las pide.

#### Migración desde el ámbito de usuario

Si `claude plugin list --json` muestra `ceo-system` con `"scope": "user"` (o
`~/.claude/settings.json` declara el marketplace como `directory` y lo habilita
en `enabledPlugins`), el hook corre en **todas** las sesiones de la máquina y los
repos cargan el working tree de este checkout, no un tag. Para pasar al modelo
por proyecto, en este orden:

1. Añade el `.claude/settings.json` anterior (con `ref` fijado, ver
   [Versiones](#versiones)) a cada repo consumidor, con un PR a `develop` por repo.
2. Ejecuta `claude plugin install ceo-system@sityos-agents --scope project` en
   cada clon.
3. Quita `ceo-system@sityos-agents` de `enabledPlugins` y el marketplace
   `sityos-agents` de `extraKnownMarketplaces` en `~/.claude/settings.json`, y
   desinstala la copia de usuario (`claude plugin uninstall
   ceo-system@sityos-agents --scope user`).
4. Comprueba que `claude plugin list --json` muestra `"projectEnabled": true`
   dentro de cada repo y que el plugin no se carga fuera de ellos.

Hasta el paso 3, el plugin sigue activo en todas las sesiones.

#### Desarrollo del plugin

Desde la raíz de este checkout:

```bash
claude --plugin-dir ./plugins/ceo-system
```

Carga el plugin del working tree solo para esa sesión. No instala nada ni toca
el perfil (`~/.claude`). Los cambios se ven al abrir una sesión nueva.

#### GitHub Actions

En CI no hay sesión interactiva, así que no valen los comandos de sesión: se
usan los comandos de terminal, con el CLI de Claude ya instalado en el runner. Como el repo es
privado, el token del step necesita acceso de lectura a
`tomasribes/sityos-agents` (el `GITHUB_TOKEN` del workflow solo ve su propio
repo; el nombre del secreto es un ejemplo).

```yaml
- name: Install ceo-system plugin
  env:
    GH_TOKEN: ${{ secrets.SITYOS_AGENTS_TOKEN }}
  run: |
    gh auth setup-git
    claude plugin marketplace add tomasribes/sityos-agents
    claude plugin install ceo-system@sityos-agents --scope project
```

### Versiones

- **Ref de distribución:** el tag `ceo-system-vX.Y.Z` sobre `master`. El
  primero es `ceo-system-v0.3.1`; `ceo-system-v0.4.0` es el primero que
  incluye el lock de dispatch, la base SHA fijada, la rama `ceo-log` y el
  guardarraíl ampliado, y es el que deben fijar los consumidores. Un cambio de
  comportamiento del plugin sube la versión en el mismo PR: si no, el tag no se
  crea y la misma versión describe dos plugins distintos. Un repo consumidor que quiera fijar la
  versión añade `ref` a la fuente del marketplace (`ref` admite una rama o un
  tag):

  ```json
  "source": {
    "source": "github",
    "repo": "tomasribes/sityos-agents",
    "ref": "ceo-system-v0.4.0"
  }
  ```

- **Una sola versión:** el catálogo (`.claude-plugin/marketplace.json`,
  `metadata.version` y `plugins[0].version`) y el plugin
  (`plugins/ceo-system/.claude-plugin/plugin.json`, `version`) llevan siempre
  la misma versión. Para comprobarlo:

  ```bash
  jq -r '.metadata.version, .plugins[0].version' .claude-plugin/marketplace.json
  jq -r .version plugins/ceo-system/.claude-plugin/plugin.json
  ```

- **Quién crea el tag:** el workflow `.github/workflows/release-tag.yml`, tras
  un run verde de `ci.yml` por push a `master`. Etiqueta ese mismo commit con
  `ceo-system-v<versión de plugin.json>` y falla sin crear tag si la versión
  no coincide con la del catálogo. Un tag existente no se mueve ni se
  sobrescribe: el run termina en verde con un aviso. Ningún agente crea ni
  empuja tags.

**Qué versión carga Claude.** `claude plugin list` muestra cada plugin
instalado con su versión, su ámbito y si está habilitado. Para ver solo
`ceo-system`:

```bash
claude plugin list --json | jq '.[] | select(.id == "ceo-system@sityos-agents") | {version, scope, enabled}'
```

`version` es la versión instalada en caché, la que carga una sesión normal. Si
no coincide con la del tag que esperas, el clon tiene una instalación antigua.
Con `claude --plugin-dir ./plugins/ceo-system` se carga el working tree, no la
caché.

### Requisitos por repo

Un repo participa en el sistema cuando tiene `goals.md` (escrito por el dueño)
y `.ceo/config.yml`. Si falta alguno, `/ceo-system:ceo-run` responde en local
`Falta <fichero>` con una línea sobre qué debe contener y termina: no lanza
subagentes, no crea issues en Linear (tampoco en `TOM`) y no escribe en
`.ceo/ceo-log.md`.

### Ciclo de trabajo

```
/ceo-system:ceo-run    → issues en Proposed
(dueño)                → Proposed → Ready
/ceo-system:dispatch   → un agente por issue Ready, en su worktree → PR a develop
/ceo-system:review     → revisión independiente por PR → Human review si no hay bloqueantes
(dueño)                → revisa y fusiona → Pending live → develop → master
/ceo-system:live-verify→ Done o Blocked
```

`/ceo-system:dispatch [DEV-19 ...]` lanza en paralelo el agente que `.ceo/config.yml`
asigna al label `role` de cada issue (`agents.dev`, `agents.docs`…), con
`isolation: worktree`, hasta llenar los huecos libres:
`min(max_open_prs − PRs abiertos, max_awaiting_human − issues en revisión)`.
Descarta los issues con label `flag`, con `blockedBy` abiertos, con rama o PR
ya existente, con rol `pm`/`tester`/`reviewer` o sin fichero de agente en
`.claude/agents/`. No mueve estados: el agente pasa el issue a In Progress al
crear la rama. Registra cada ejecución en `.ceo/ceo-log.md`.

Solo corre un dispatch a la vez por clon. Tras los kill-switches crea el lock
`ceo-dispatch.lock` con `mkdir` en `git rev-parse --git-common-dir` (compartido
por el checkout principal y todos sus worktrees, sin versionar). Si ya existe, el
segundo dispatch responde `Dispatch en curso (lock <ruta> desde <fecha>)` y sale
sin tocar Linear, ramas, PRs ni el log. El lock se libera con `rmdir` como último
paso de toda salida posterior (incluidas `Sin huecos` y un fallo de agente). No
caduca: si queda huérfano, el mensaje trae el `rmdir` exacto para quitarlo a mano.
Justo antes de lanzar cada agente, el dispatcher relee el issue: si ya no está en
Ready, tiene un label `flag` o un `blockedBy` abierto, no lo toca y lo anota en
`Descartados` como `cambió antes de lanzar (<estado o label>)`.
Tras tomar el lock, el dispatcher hace `git fetch origin <base>` y fija una sola
vez `BASE_SHA=$(git rev-parse origin/<base>)`; la línea `Huecos` del log lo
muestra como `base <base>@<sha corto>`. Cada agente recibe en su prompt la línea
`Base: origin/<base> @ <BASE_SHA>. Crea tu rama desde ese commit.` (el agente
`dev-plugin` crea la rama con `git switch -c <rama> <sha>` y comprueba `HEAD`).
Al terminar, por cada rama empujada ejecuta `git merge-base --is-ancestor
<BASE_SHA> origin/<rama>`: si la rama no contiene la base (por ejemplo, el
worktree arrancó en `master`), `Lanzados` la marca `ERROR: rama no contiene base
<sha corto>` y el dispatcher no toca el issue ni el PR. La comprobación vale para
cualquier agente, aunque no conozca la línea `Base:`.

**ceo-log.md:** `ceo-run`, `live-verify` y `dispatch` nunca commitean ni
pushean el log en `branches.base` (`develop`) ni tocan el checkout del dueño.
Cada ejecución añade su entrada como commit nuevo en la rama `ceo-log`, desde
un worktree persistente en `.claude/worktrees/ceo-log`, y la pushea sin forzar.
Esa rama tiene un único PR acumulado contra `develop`: si no hay uno abierto, el
comando lo crea; si lo hay, añade el commit a él. El dueño lo fusiona **con
merge commit** cuando le convenga y la siguiente ejecución abre uno nuevo. Ese
PR no cuenta en `max_open_prs`. El CEO lee el log del worktree `ceo-log` (que
incluye las entradas sin fusionar) y, si no existe, `.ceo/ceo-log.md`. Si el
worktree tiene cambios o commits sin publicar, o el push se rechaza (p. ej.
tras fusionar con squash), el comando no reintenta y muestra la entrada con
`ceo-log sin publicar: <motivo>`. No borres ese worktree al limpiar los de los
agentes.

Al publicar, el comando añade bajo cada encabezado `###` la línea `- Ejecución:`
(ID de ejecución `<comando>-<UTC>`, versión instalada de `ceo-system` según
`claude plugin list --json`, o `desconocida`, y repo según `gh repo view`) y
cierra la entrada con una sola línea `- Errores:` (fallos de subagentes, bloques
`## Log` ausentes, `ERROR:` de `Lanzados`, o `ninguno`). En `ceo-run` los
bloques del verificador y del CEO comparten la misma línea `- Ejecución:`:

```
### 2026-11-26T09:15Z · sityos-agents · dispatch
- Ejecución: dispatch-20261126T091500Z · ceo-system 0.3.1 · tomasribes/sityos-agents
- Huecos: 1 (PRs abiertos 1/2 · en revisión 1/3)
- Lanzados: DEV-50 → dev-plugin · In Review · #21
- Descartados y motivo: ninguno
- Lecciones: Ninguna
- Errores: ninguno
```

Para que un repo pueda despachar necesita su agente de desarrollo en
`.claude/agents/<nombre>.md` (p. ej. `dev-python` en job-finder,
`dev-typescript` en finanzas-mcp) y `.claude/worktrees/` en `.gitignore`.

Desde 0.5.0 el agente de desarrollo del repo solo describe su stack (entorno,
normas, condiciones de parada extra) y precarga `skills: ceo-system:dev-protocol`, que
lleva el protocolo común: arranque, rama desde la base fijada, zonas, gate y
`never_run` leídos de `.ceo/config.yml`, commits, PR y respuesta. Plantilla y criterio
de qué es global y qué es local: [`docs/agents-battery.md`](docs/agents-battery.md).

`/ceo-system:review [PR ...]` lanza `agents.reviewer` (p. ej. `ceo-system:review-code`)
sobre los PRs abiertos cuyo issue está en In Review, como máximo 3 por ejecución y
nunca dos veces sobre el mismo head. El revisor trabaja en solo lectura sobre un SHA
fijado, verifica cada hallazgo contra ruta y línea, publica un comentario y mueve el
issue a Human review si no hay bloqueantes. Nunca aprueba ni fusiona y no escribe en
`ceo-log.md`.

### Guardarraíl

El hook bloquea (exit 2): push a `master`/`main` y forzados, `git reset --hard`,
`gh pr merge`, `rm -rf`, drush destructivo (`sql-drop`, `si`), `docker compose down -v`,
scripts de deploy/provisioning, `doctl`, los targets `make` que tocan producción
o restauran una BD (`upload-backup`, `download-*-from-prod`, `cim-live`,
`restore-db`), `gh workflow run` de workflows de deploy, release o rollback, y
lectura de `.env`, claves, `ai-keys*` y los directorios `secrets/`,
`credentials/`, `keys/`, `private-files/` y `backups/` (permitidos
`.env.example` y similares). La palabra `keys` solo cuenta como directorio
(`keys/`), para no bloquear `jq keys`.
Las reglas de secretos se aplican al texto del comando: un mensaje de commit
que nombra una de esas rutas también se bloquea. Pásalo con `git commit -F <fichero>`.
Las reglas git se aplican también con opciones globales entre `git` y el
subcomando (`git -C <ruta>`, `-c k=v`, `--git-dir`, `--work-tree`, `--no-pager`…):
`git -C /repo push origin master` se bloquea igual que `git push origin master`.
Una opción global no reconocida antes de `push`, `reset`, `clean` o `branch`
(`git --literal-pathspecs push …`, `git --exec-path=… reset …`) bloquea la llamada.
Se activa en **todas** las sesiones donde el plugin esté habilitado, también
las interactivas. Antes de cambiarlo:

```bash
bash plugins/ceo-system/tests/deny-dangerous.test.sh   # exit 0 = todo verde
claude plugin validate --strict .
```

### Kill-switches

| Ámbito | Cómo |
|---|---|
| Proyecto | Project label `agent-paused` en Linear (`ceo-run`, `live-verify` y `dispatch` salen sin hacer nada; el verificador tampoco se lanza) |
| Issue | Issue label `agent-paused` |
| Repo | Fichero `.ceo/PAUSE` |

### Codex CLI

El plugin está pensado para Claude Code. En Codex no es seguro todavía: Codex usa
una copia en caché desfasada, no tiene los agentes del plugin y no aplica el
guardarraíl hasta que lo marcas como de confianza. Estado por componente, pruebas
y cambios pendientes: [`docs/compat/codex.md`](docs/compat/codex.md).

Espejo de los agentes de un repo para Codex: `.codex/agents/*.toml` se genera desde
`.claude/agents/*.md` con `tools/sync-codex-agents.sh <repo>` (`--check` falla si hay
desfase). No se edita a mano.
