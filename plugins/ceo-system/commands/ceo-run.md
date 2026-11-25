---
description: Run the CEO planning cycle for the project of the current repo (live verification, then goals.md -> Linear issues in Proposed)
---

Ejecuta el ciclo del CEO sobre el repo actual. Pasos, en orden:

1. Si existe `.ceo/PAUSE` en la raíz del repo, responde `Repo en pausa (.ceo/PAUSE)` y termina.
2. Comprueba que existen `goals.md` y `.ceo/config.yml` en la raíz del repo. Por cada fichero que falte, responde una línea y termina:
   - `Falta goals.md`: objetivos, Key Results y la lista de **Active milestones** del periodo, escritos por el dueño.
   - `Falta .ceo/config.yml`: el contrato CEO del repo (`linear.team`, `linear.project`, `linear.states`, `branches.base`, `limits`, `autonomy`, `zones`).

   No delegues en ningún subagente, no escribas en Linear ni en `.ceo/ceo-log.md` y no hagas commit.
3. Lee `linear.project` de `.ceo/config.yml`. Si el proyecto de Linear tiene el **project label** `agent-paused`, responde `Proyecto en pausa (agent-paused)` y termina. No delegues en ningún subagente ni escribas el log.
4. **Verificación en producción.** Delega en el subagente `ceo-system:verifier`. Pásale la ruta absoluta del repo y la fecha actual en UTC. Espera a que termine antes de seguir, para que el CEO planifique con los estados al día. Si falla, registra el error (ver abajo) y sigue con el paso 5.
5. Delega en el subagente `ceo-system:ceo` el ciclo completo. Pásale la ruta absoluta del repo y la fecha actual en UTC. No añadas instrucciones propias ni reinterpretes las suyas. No le pases la respuesta del verificador: el CEO lee el resultado en Linear.
6. Cuando terminen, toma literalmente el bloque bajo `## Log` de cada respuesta, primero el del verificador y después el del CEO. Añádelos al final de `.ceo/ceo-log.md` (créalo con el encabezado `# CEO log` si no existe). Es el único fichero que tocas.
7. **Commit del log** (directo a la rama base, sin PR). Lee `branches.base` de `.ceo/config.yml` (`develop` si no está). Si `.ceo/ceo-log.md` no tiene cambios, sáltalo. Si la rama actual (`git rev-parse --abbrev-ref HEAD`) no es la base, no hagas commit y añade al final de tu respuesta `ceo-log.md sin commitear: checkout en <rama>`. Si es la base:
   1. `git add .ceo/ceo-log.md && git commit -m "Update CEO log: ceo-run <fecha UTC>" -- .ceo/ceo-log.md`. Solo ese fichero, aunque haya otros cambios o ficheros en stage. Sin trailers.
   2. `git pull --rebase --autostash origin <base>`. Si hay conflicto, `git rebase --abort`, no hagas push y avísame.
   3. `git push origin <base>`. Nunca push forzado ni a otra rama. Si falla, avísame con el error y no reintentes.
8. Muéstrame solo los bloques de Informe: primero el del verificador, con el encabezado `## Verificación en producción`; después el del CEO, con el encabezado `## Informe`.

Si un subagente falla o no devuelve los dos bloques, añade igualmente al log una entrada `### <fecha> · ERROR` (`### <fecha> · live-verify · ERROR` para el verificador) con el motivo y dímelo.

Las entradas de ERROR también se commitean con el paso 7.
