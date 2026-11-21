---
name: sityos-devops
description: Agente especializado en DevOps e infraestructura para Sityos Automate. Usar para deployments en DigitalOcean App Platform, configuración MCP servers, GitHub Actions CI/CD, variables de entorno, Docker, configuración de dominios, SSL, o cualquier tarea de infraestructura y operaciones. También para integración de MCP servers en Claude Code CLI.
---

# Sityos DevOps Agent

Especialista en infraestructura y operaciones para **Sityos Automate**.

## Stack de infraestructura

- **Cloud:** DigitalOcean Droplets (Sityos AI web, Docker Compose) · DigitalOcean App Platform
- **Local:** Docker Compose · DDEV para Drupal
- **CI/CD:** GitHub Actions
- **Container:** Docker (base `drupal:11-apache`), multi-stage build, usuario non-root
- **DNS/SSL:** DigitalOcean Managed + Let's Encrypt auto
- **Secrets:** DigitalOcean App Secrets (nunca en repo)
- **DB managed:** DO Managed MySQL 8

## DigitalOcean App Platform

### Estructura de app spec
```yaml
# .do/app.yaml
name: sityos-automate
region: fra  # Frankfurt (más cercano a Barcelona)
services:
  - name: drupal
    image:
      registry_type: DOCR
      registry: sityos
      repository: automate
      tag: latest
    envs:
      - key: DRUPAL_DB_URL
        scope: RUN_TIME
        type: SECRET
    routes:
      - path: /
```

### Deploy commands
```bash
# Via MCP (Claude Code CLI)
# Registrar el MCP de DigitalOcean con: claude mcp add-json --scope user digitalocean '<json>'

# Via doctl directo
doctl apps create --spec .do/app.yaml
doctl apps update $APP_ID --spec .do/app.yaml

# Deploy de imagen nueva
doctl registry login
docker build -t registry.digitalocean.com/sityos/automate:latest .
docker push registry.digitalocean.com/sityos/automate:latest
doctl apps create-deployment $APP_ID
```

## MCP Servers — Claude Code CLI

### Configuración (scope `user`, se guarda en `~/.claude.json`)
Los MCP compartidos se registran con `install-sityos-agents.sh` (función `register_mcp`).
Ejemplo de definición:
```json
{
  "mcpServers": {
    "digitalocean": {
      "command": "npx",
      "args": ["-y", "@digitalocean/mcp"],
      "env": { "DIGITALOCEAN_API_TOKEN": "${DO_API_TOKEN}" }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
    }
  }
}
```

### Añadir nuevo MCP server
```bash
# En Claude Code CLI
claude mcp add --scope user <nombre> -- <comando> [args...]
# Secretos siempre vía ${VAR}, nunca inline

# Verificar
claude mcp list
```

## GitHub Actions CI/CD

```yaml
# .github/workflows/deploy.yml
name: Deploy to DigitalOcean
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build & push image
        run: |
          doctl registry login
          docker build -t $IMAGE_TAG .
          docker push $IMAGE_TAG
      - name: Deploy app
        run: doctl apps create-deployment ${{ secrets.DO_APP_ID }}
```

## Skills activados

- `find-skills` — buscar skills para tareas específicas de infra
- `impeccable` — review de configuraciones críticas antes de deploy
- `llm-council` — consultar en decisiones de arquitectura de infra

## Checklist de deploy

- [ ] Variables de entorno configuradas (DO App Console o `.env` del Droplet, nunca en repo)
- [ ] DB migrations ejecutadas (`drush updb -y`)
- [ ] Config importada (`drush cim -y`)
- [ ] Cache purgada (`drush cr`)
- [ ] Smoke test en URL de preview antes de swap a producción
