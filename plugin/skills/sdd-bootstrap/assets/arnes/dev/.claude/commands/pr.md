---
description: "Prepara y abre un pull request limpio de la rama actual. Uso: /pr"
---

Abre un PR de la rama actual.

1. Confirma que no estás en `main`. Si hay cambios sin commit, agrúpalos en commits pequeños con mensajes en imperativo (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).
2. Corre los comandos de verificación del `CLAUDE.md`. Si algo falla, para y repórtalo; no abras un PR rojo.
3. Lee todo el historial de la rama (`git log main..HEAD`, `git diff main...HEAD`), no solo el último commit.
4. `git push -u origin <rama>` y `gh pr create` con esta descripción:
   - **Qué hace** (2 a 4 líneas, lo que hace el código ahora).
   - **Por qué** (enlace al issue o a la spec en `spec/features/`).
   - **Cómo se verificó** (comandos y su resultado).
   - **Riesgos o pendientes**, si los hay.
5. Devuelve el enlace del PR.
