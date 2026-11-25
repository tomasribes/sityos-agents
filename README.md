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
│   └── pm.md                          → ceo-system:pm        (digest diario, solo lectura)
├── commands/
│   ├── ceo-run.md                     → /ceo-system:ceo-run      (goals.md → issues en Proposed)
│   ├── dispatch.md                    → /ceo-system:dispatch     (issues Ready → agentes → PRs)
│   ├── live-verify.md                 → /ceo-system:live-verify  (Pending live → Done/Blocked)
│   └── pm-digest.md                   → /ceo-system:pm-digest
├── skills/
│   ├── linear-conventions/SKILL.md    estados, labels, transiciones, contrato de issue
│   └── pr-contract/SKILL.md           formato y límites de PR
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
  primero es `ceo-system-v0.3.1`. Un repo consumidor que quiera fijar la
  versión añade `ref` a la fuente del marketplace (`ref` admite una rama o un
  tag):

  ```json
  "source": {
    "source": "github",
    "repo": "tomasribes/sityos-agents",
    "ref": "ceo-system-v0.3.1"
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
y `.ceo/config.yml`. Sin ellos, `/ceo-system:ceo-run` crea un único issue en
`TOM` avisando de lo que falta y no hace nada más.

### Ciclo de trabajo

```
/ceo-system:ceo-run    → issues en Proposed
(dueño)                → Proposed → Ready
/ceo-system:dispatch   → un agente por issue Ready, en su worktree → PR a develop
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

**ceo-log.md:** `ceo-run`, `live-verify` y `dispatch` añaden su entrada a
`.ceo/ceo-log.md` y la commitean directamente en `branches.base` (`develop`), sin
PR: commit de solo ese fichero, `pull --rebase --autostash` y push. Si el
checkout no está en la rama base, o el rebase/push falla, el fichero queda sin
commitear y el comando lo avisa.

Para que un repo pueda despachar necesita su agente de desarrollo en
`.claude/agents/<nombre>.md` (p. ej. `dev-python` en job-finder,
`dev-typescript` en finanzas-mcp) y `.claude/worktrees/` en `.gitignore`.

### Guardarraíl

El hook bloquea (exit 2): push a `master`/`main` y forzados, `git reset --hard`,
`gh pr merge`, `rm -rf`, drush destructivo (`sql-drop`, `si`), `docker compose down -v`,
scripts de deploy/provisioning, `doctl`, y lectura de `.env`, claves y
directorios `secrets/`/`credentials/` (permitidos `.env.example` y similares).
Se activa en **todas** las sesiones donde el plugin esté habilitado, también
las interactivas. Antes de cambiarlo:

```bash
bash plugins/ceo-system/tests/deny-dangerous.test.sh   # exit 0 = todo verde
claude plugin validate --strict .
```

### Kill-switches

| Ámbito | Cómo |
|---|---|
| Proyecto | Project label `agent-paused` en Linear (CEO y dispatcher salen sin hacer nada) |
| Issue | Issue label `agent-paused` |
| Repo | Fichero `.ceo/PAUSE` |
