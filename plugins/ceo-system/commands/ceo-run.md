---
description: Run the CEO planning cycle for the project of the current repo (live verification, then goals.md -> Linear issues in Proposed)
---

Ejecuta el ciclo del CEO sobre el repo actual. Pasos, en orden:

1. Si existe `.ceo/PAUSE` en la raíz del repo, responde `Repo en pausa (.ceo/PAUSE)` y termina.
2. Comprueba que existen `.ceo/config.yml` y `goals.md`. Si falta alguno, salta el paso 3 y no termines aquí: el subagente CEO sabe cómo reportarlo.
3. **Verificación en producción.** Delega en el subagente `ceo-system:verifier`. Pásale la ruta absoluta del repo y la fecha actual en UTC. Espera a que termine antes de seguir, para que el CEO planifique con los estados al día. Si falla, registra el error (ver abajo) y sigue con el paso 4.
4. Delega en el subagente `ceo-system:ceo` el ciclo completo. Pásale la ruta absoluta del repo y la fecha actual en UTC. No añadas instrucciones propias ni reinterpretes las suyas. No le pases la respuesta del verificador: el CEO lee el resultado en Linear.
5. Cuando terminen, toma literalmente el bloque bajo `## Log` de cada respuesta, primero el del verificador y después el del CEO. Añádelos al final de `.ceo/ceo-log.md` (créalo con el encabezado `# CEO log` si no existe). Es el único fichero que tocas. No hagas commit.
6. Muéstrame solo los bloques de Informe: primero el del verificador, con el encabezado `## Verificación en producción`; después el del CEO, con el encabezado `## Informe`.

Si un subagente falla o no devuelve los dos bloques, añade igualmente al log una entrada `### <fecha> · ERROR` (`### <fecha> · live-verify · ERROR` para el verificador) con el motivo y dímelo.
