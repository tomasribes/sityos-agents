# Comando: /drupal-module
# Scaffolding de módulo custom Drupal 11 para Sityos Automate
#
# Uso: /drupal-module <nombre>
# Ejemplo: /drupal-module sityos_ai_embeddings

Crea un módulo custom Drupal 11 completo con el nombre `$ARGUMENTS`.

## Lo que debe generarse

1. **`$ARGUMENTS.info.yml`** — Metadata del módulo
   - type: module
   - core_version_requirement: ^10 || ^11
   - package: Sityos
   - dependencies mínimas (solo las necesarias)

2. **Hooks** — Preferir Event subscribers / Plugins; si hace falta un hook, clase en `src/Hook/` con `#[Hook]` (Drupal 11.1+).
   `$ARGUMENTS.module` solo si se requiere compatibilidad D10 o no hay alternativa OOP.

3. **`$ARGUMENTS.services.yml`** — Si el módulo necesita servicios

4. **`src/`** — Estructura de clases según lo que haga el módulo:
   - Controller/ si hay rutas
   - Form/ si hay formularios
   - Plugin/ si hay plugins
   - Service/ para lógica de negocio (siempre extraer a servicio)
   - Hook/ y EventSubscriber/ según corresponda

5. **`config/install/`** — Config por defecto si aplica

## Estándares obligatorios

- Namespacing: `Drupal\$ARGUMENTS\`
- DI container para todos los servicios (no \Drupal::service() en clases)
- Type hints en todos los métodos
- DocBlocks en clases y métodos públicos
- Cache tags + contexts en todo render dinámico
- Debe pasar `phpcs` (Drupal + DrupalPractice) y `phpstan` nivel 6
- Ningún `var_dump`, `print_r` o `dsm()` en código entregado

## Output

Mostrar estructura de archivos primero (árbol), luego el contenido de cada archivo.
Preguntar si hay dependencias adicionales antes de generar.
