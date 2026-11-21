# Sityos Automate — Project CLAUDE.md
# Ubicación: ~/ai-projects/AI-Automation/CLAUDE.md
# Hereda de: ~/.claude/CLAUDE.md (global)

## Contexto del proyecto

**Producto:** Sityos Automate — plataforma B2B de automatización e IA
**Repo:** github.com/sityos/automate
**Deploy:** DigitalOcean Droplet (Docker Compose) · App Platform (región Frankfurt) como alternativa
**URL prod:** https://automate.sityos.com

---

## Stack específico de este proyecto

```
drupal/         → Drupal 11 core + custom modules
web/            → Docroot público
themes/custom/  → sityos_automate_theme (Twig + SCSS 7-1/BEM + critical.css, hereda de contrib base theme)
modules/custom/ → sityos_ai_*, sityos_workflow_*, sityos_integrations_*
.do/            → DigitalOcean app spec
.github/        → GitHub Actions workflows
```

## Variables de entorno requeridas

```bash
# Ver .env.example — NUNCA commitear .env real
DRUPAL_DB_URL=mysql://user:pass@host/db
DRUPAL_HASH_SALT=<generado con drush php-eval>
DO_API_TOKEN=<DigitalOcean API token>
ANTHROPIC_API_KEY=<para módulos de IA>
```

## Comandos frecuentes del proyecto

```bash
# Dev local
ddev start && ddev drush cr

# Build theme
cd themes/custom/sityos_automate_theme && npm run build

# Tests
./vendor/bin/phpunit --group sityos

# Deploy staging
git push origin main  # GitHub Action lo despliega automáticamente

# Deploy prod (manual)
# Droplet:      ssh <droplet> 'cd <app> && docker compose pull && docker compose up -d && docker compose exec drupal drush deploy'
# App Platform: doctl apps create-deployment $DO_APP_ID_PROD
```

## Custom slash commands disponibles

```bash
# En Claude Code CLI dentro de este proyecto:
/drupal-module <nombre>      → Scaffolding de módulo custom Drupal
/content-page <tipo> <tema>  → Draft de página trilingual (ES/EN/CA)

# Deploy, componentes de theme y scope docs → skills /sityos-devops, /sityos-frontend, /sityos-content
```

## Módulos custom activos

| Módulo | Propósito |
|--------|-----------|
| `sityos_ai_chat` | Widget de chat IA embeddable |
| `sityos_workflow` | Orquestación de workflows |
| `sityos_integrations` | Conectores externos (REST/webhook) |
| `sityos_analytics` | Dashboard de métricas |

## Decisiones de arquitectura tomadas

- **API-first:** JSON:API habilitado, REST deshabilitado
- **Auth:** OAuth2 + JWT (simple_oauth contrib)
- **Cache:** Redis en prod, DB cache en dev
- **Queue:** Drupal Queue API + cron (no RabbitMQ por ahora)
- **i18n:** Langcode EN base, ES + CA como traducciones

## Agentes y skills activos en este proyecto

Heredados del global + overrides:

- Skills `sityos-*` en scope user (`~/.claude/skills/`, symlinks a `~/ai-projects/sityos-agents`)
- Verificar: `ls -la ~/.claude/skills | grep sityos`

## Notas de desarrollo

- **PHPStan:** nivel 6 como mínimo en módulos custom
- **PHPCS:** standard Drupal + DrupalPractice
- **Twig:** debug activado en dev (`twig.config.debug: true`)
- **Config split:** `dev` / `staging` / `prod`
