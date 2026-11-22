---
description: Verify on the live site the issues merged and deployed (Pending live -> Done or Blocked)
---

Ejecuta la verificación en producción sobre el repo actual. Pasos, en orden:

1. Si existe `.ceo/PAUSE` en la raíz del repo, responde `Repo en pausa (.ceo/PAUSE)` y termina.
2. Si no existe `.ceo/config.yml`, responde `Falta .ceo/config.yml` y termina.
3. Delega en el subagente `ceo-system:verifier`. Pásale la ruta absoluta del repo y la fecha actual en UTC. No añadas instrucciones propias ni reinterpretes las suyas.
4. Cuando termine, toma literalmente el bloque bajo `## Log` de su respuesta y añádelo al final de `.ceo/ceo-log.md` (créalo con el encabezado `# CEO log` si no existe). Es el único fichero que tocas. No hagas commit.
5. Muéstrame solo el bloque `## Informe`.

Si el subagente falla o no devuelve los dos bloques, añade igualmente al log una entrada `### <fecha> · live-verify · ERROR` con el motivo y dímelo.
