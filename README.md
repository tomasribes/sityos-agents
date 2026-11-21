# SITYOS Agent System

Sistema de agentes y skills para el ecosistema **SITYOS AI / Sityos Automate**.

## Estructura

```
sityos-agents/
├── install-sityos-agents.sh        ← Script de instalación
├── global/
│   └── CLAUDE.md                   → ~/.claude/CLAUDE.md (solo con --link-claude-md)
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
bash install-sityos-agents.sh                    # skills + MCP de usuario
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
- Sección Ruflo (la regenera `ruflo init`; al ser symlink, los cambios aparecen en el repo)

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
estado de Ruflo/claude-flow (`.claude-flow/`, `.swarm/`, `.hive-mind/`, `*.db`),
backups del script (`*.backup.*`), `.DS_Store` y secretos. `project-override/.claude/`
sí se versiona (el patrón `/.claude/` solo aplica a la raíz).

## Actualizar un agente

```bash
# Editar agents/<nombre>/SKILL.md — al ser symlink no hace falta reinstalar.
# Para un agente nuevo: crear agents/<nombre>/SKILL.md y volver a ejecutar el script.
```
