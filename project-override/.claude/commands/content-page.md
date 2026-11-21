# Comando: /content-page
# Draft de página trilingual para Sityos Automate
#
# Uso: /content-page <tipo> <tema>
# Ejemplo: /content-page landing automatizacion-rrhh

Genera el copy completo para una página de Sityos Automate sobre `$ARGUMENTS`.

## Output requerido

Generar en paralelo en 3 idiomas con esta estructura:

### ES (principal)
- **H1:** [Beneficio concreto — máx 8 palabras]
- **Subheadline:** [Cómo + para quién — 1 frase]
- **Body intro:** [2-3 párrafos, tono técnico-accesible]
- **3 Feature bullets:** [Icono emoji] + Título + Descripción corta
- **CTA:** [Texto botón] + [Texto secundario]
- **Meta title:** [60 chars max]
- **Meta description:** [155 chars max]

### EN
[Misma estructura — no traducción literal, adaptar al mercado EN]

### CA
[Solo si se solicita explícitamente]

## Reglas de brand voice

- Nunca usar: "revolucionario", "disruptivo", "innovador", "potente"
- Siempre: beneficio concreto antes que feature técnico
- Datos > adjetivos cuando sea posible
- CTA: acción concreta ("Ver demo en vivo", no "Descúbrelo")

## SEO

Incluir al final:
- Keyword principal sugerida
- 3 keywords secundarias
- Sugerencia de URL slug
