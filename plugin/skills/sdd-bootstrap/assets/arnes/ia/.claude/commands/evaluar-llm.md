---
description: "Crea o corre el set de evaluación de una función que usa un LLM, y compara antes contra después. Uso: /evaluar-llm <función o cambio>"
argument-hint: <función, prompt o cambio a evaluar>
---

Evalúa: $ARGUMENTS

Sigue `.claude/rules/llm-apps.md` y las skills `llm-evaluation` y `eval-harness-first`.

1. **Busca el set existente** en `evals/`. Si no existe, créalo:
   - `evals/<nombre>/casos.jsonl`: mínimo 30 casos reales o realistas, cada uno con `input`, `esperado` (respuesta o criterio verificable) y `modo_falla` (inventa, formato, rechazo, seguridad, otro).
   - Incluye casos difíciles y adversarios (prompt injection, entradas vacías, idioma distinto, documentos sin la respuesta).
   - Muéstrame 5 casos de ejemplo y espera mi visto bueno antes de seguir.
2. **Calificadores**: primero los deterministas (esquema válido, contiene / no contiene, coincidencia exacta, regex). LLM como juez solo donde haga falta, con una rúbrica escrita y validada contra etiquetas humanas.
3. **Runner** `evals/<nombre>/run.py` que guarde por caso: salida, puntuación, tokens, latencia y costo, en `evals/<nombre>/resultados/<fecha>-<git-sha>.jsonl`. Respuestas del modelo con temperatura fija y versión de modelo fijada.
4. **Corre** la versión actual (antes) y la nueva (después) sobre el mismo set.
5. **Reporta** una tabla por modo de falla: antes, después, diferencia; más costo y latencia p50/p95. Lista los casos que empeoraron. Conclusión en una frase: ¿se queda el cambio?
