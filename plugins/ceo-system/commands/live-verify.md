---
description: Verify on the live site the issues merged and deployed (Pending live -> Done or Blocked)
---

Ejecuta la verificación en producción sobre el repo actual. Pasos, en orden:

1. Si existe `.ceo/PAUSE` en la raíz del repo, responde `Repo en pausa (.ceo/PAUSE)` y termina.
2. Si no existe `.ceo/config.yml`, responde `Falta .ceo/config.yml` y termina.
3. Delega en el subagente `ceo-system:verifier`. Pásale la ruta absoluta del repo y la fecha actual en UTC. No añadas instrucciones propias ni reinterpretes las suyas.
4. Cuando termine, toma literalmente el bloque bajo `## Log` de su respuesta y añádelo al final de `.ceo/ceo-log.md` (créalo con el encabezado `# CEO log` si no existe). Es el único fichero que tocas.
5. **Commit del log** (directo a la rama base, sin PR). Lee `branches.base` de `.ceo/config.yml` (`develop` si no está). Si `.ceo/ceo-log.md` no tiene cambios, sáltalo. Si la rama actual (`git rev-parse --abbrev-ref HEAD`) no es la base, no hagas commit y añade al final de tu respuesta `ceo-log.md sin commitear: checkout en <rama>`. Si es la base:
   1. `git add .ceo/ceo-log.md && git commit -m "Update CEO log: live-verify <fecha UTC>" -- .ceo/ceo-log.md`. Solo ese fichero, aunque haya otros cambios o ficheros en stage. Sin trailers.
   2. `git pull --rebase --autostash origin <base>`. Si hay conflicto, `git rebase --abort`, no hagas push y avísame.
   3. `git push origin <base>`. Nunca push forzado ni a otra rama. Si falla, avísame con el error y no reintentes.
6. Muéstrame solo el bloque `## Informe`.

Si el subagente falla o no devuelve los dos bloques, añade igualmente al log una entrada `### <fecha> · live-verify · ERROR` con el motivo y dímelo.

Las entradas de ERROR también se commitean con el paso 5.
