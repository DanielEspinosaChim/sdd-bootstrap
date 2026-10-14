---
description: "Diseña y corre un experimento de ML reproducible: hipótesis, baseline, métrica, split y registro de resultados. Uso: /experimento <hipótesis>"
argument-hint: <hipótesis o idea a probar>
---

Diseña y corre un experimento para probar: $ARGUMENTS

Sigue `.claude/rules/ml-datos.md` y la skill `mle-workflow`.

1. **Ficha del experimento** en `experiments/<AAAA-MM-DD>-<nombre>/README.md`, antes de correr nada:
   - Hipótesis y la decisión que cambia si se confirma.
   - Métrica principal y umbral de éxito; métricas secundarias (costo, latencia, equidad por segmento si aplica).
   - Dataset, versión y split (por tiempo si los datos tienen orden temporal). Confirma que no hay fuga entre splits.
   - Baseline contra el que se compara (el modelo actual o uno simple). Sin baseline no hay experimento.
   - Semillas.
   **Muéstrame la ficha y espera mi visto bueno** si el experimento tarda más de 10 minutos o cuesta dinero.
2. **Código** en `experiments/<...>/` o en `src/` si es reutilizable, con un test de humo que corra en menos de un minuto con datos pequeños.
3. **Corre** baseline y variante con las mismas semillas y el mismo split. Guarda configuración, métricas y versión del código (`git rev-parse HEAD`) en `results.json`.
4. **Reporta**: tabla baseline contra variante, intervalo de confianza o al menos varias semillas si la diferencia es pequeña, y la conclusión en una frase. Si la diferencia está dentro del ruido, dilo.
5. No cambies la métrica, el split ni el umbral después de ver resultados. Si crees que debían cambiar, dilo explícitamente como una desviación de la ficha.
