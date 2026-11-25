# AGENTS.md — sityos-agents

Instrucciones para quien mantiene este repo (personas y agentes). La instalación en
repos consumidores y el uso del plugin están en [`README.md`](README.md): no se
repiten aquí.

Este repo es la fuente del `CLAUDE.md` global, de las skills `sityos-*` y del plugin
`ceo-system`. Un error aquí afecta a todas las sesiones del dueño y a todos los repos
del sistema CEO.

## Componentes

| Ruta | Responsabilidad | Quién lo consume |
|---|---|---|
| `global/CLAUDE.md` | Instrucciones globales; symlink a `~/.claude/CLAUDE.md` | Todas las sesiones de Claude Code del dueño |
| `agents/sityos-*/SKILL.md` | Skills `sityos-*` (el directorio se llama `agents/`, pero son skills); el instalador las enlaza en `~/.claude/skills` | Sesiones del dueño en proyectos Sityos |
| `project-override/` | Plantilla de `CLAUDE.md` y comandos (`.claude/commands/`) para un proyecto Drupal | `install-sityos-agents.sh --project <ruta>` |
| `install-sityos-agents.sh` | Instalador: escribe en `~/.claude` (skills, MCP de usuario, symlink del global) | Solo el dueño, a mano |
| `.claude-plugin/marketplace.json` | Catálogo del marketplace `sityos-agents` | Claude Code de los repos consumidores |
| `plugins/ceo-system/` | Plugin: `agents/`, `commands/`, `skills/`, `hooks/`, `tests/` y `.claude-plugin/plugin.json` | Repos con `ceo-system@sityos-agents` habilitado |
| `.claude/agents/dev-plugin.md` | Agente dev de este repo (`agents.dev` en `.ceo/config.yml`) | `/ceo-system:dispatch` en este repo |
| `.github/workflows/ci.yml` | Gate en GitHub Actions; un run verde en `master` es la señal "live" | Pushes y PRs a `develop`/`master` · verificador (`live.deploy_workflow`) |
| `.github/workflows/release-tag.yml` | Crea el tag `ceo-system-vX.Y.Z` tras un `ci.yml` verde en `master` | Repos consumidores que fijan `ref` |
| `.ceo/` | Contrato CEO del repo (`.ceo/config.yml`) y log; solo el dueño | Agentes y comandos de `ceo-system` |
| `goals.md` | Objetivos y Key Results del periodo; solo el dueño | Agente CEO (`/ceo-system:ceo-run`) |
| `docs/audits/` | Auditorías de arquitectura (origen de los KR) | Dueño y agente CEO |

## Comprobación

Desde la raíz, en este orden (`gate.commands` de `.ceo/config.yml`). Todo en verde
antes de abrir un PR:

```bash
bash -n install-sityos-agents.sh plugins/ceo-system/hooks/deny-dangerous.sh plugins/ceo-system/tests/deny-dangerous.test.sh
bash plugins/ceo-system/tests/deny-dangerous.test.sh
claude plugin validate --strict .
claude plugin validate --strict ./plugins/ceo-system
```

1. Sintaxis de los scripts Bash.
2. Casos permitidos y bloqueados del guardarraíl (exit 0 = todo verde).
3. Manifiesto del marketplace.
4. Manifiesto y componentes del plugin.

`ci.yml` repite los cuatro y añade:

```bash
shellcheck -S error install-sityos-agents.sh plugins/ceo-system/hooks/*.sh plugins/ceo-system/tests/*.sh
```

## Lo que no se ejecuta

Cambian el perfil de la máquina del dueño o los plugins instalados
(`gate.never_run`). Ningún agente los ejecuta:

```
bash install-sityos-agents.sh
claude plugin install
claude plugin update
claude plugin marketplace add
claude plugin marketplace update
claude mcp add
```

Para probar el plugin sin instalarlo, ver `CLAUDE.md` (`--plugin-dir`).

## Ramas y zonas

- Base: `develop`. Una rama y un PR contra `develop` por issue.
- `master` es protegida: solo el dueño fusiona `develop` → `master`. Nunca push a
  `master` ni `--force`.
- Las zonas `human_only`, `forbidden` y `sandbox` se definen en `zones` de
  `.ceo/config.yml`, que es la única fuente. Consúltalas allí antes de tocar un fichero.

## Convenciones

- Código, comentarios y commits en inglés. Prompts de agentes y documentación de
  usuario en español.
- Un cambio de comportamiento del plugin actualiza el `README.md` en un commit aparte
  del mismo PR.
- Un cambio en `plugins/ceo-system/hooks/deny-dangerous.sh` añade sus casos a
  `plugins/ceo-system/tests/deny-dangerous.test.sh`. El hook falla cerrado: no se
  debilita para que un test pase.
