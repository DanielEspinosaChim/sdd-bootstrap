---
description: "Revisa un pipeline de datos, entrenamiento, RAG o inferencia antes de llevarlo a producción. Uso: /auditar-modelo [ruta o área]"
argument-hint: "[ruta o área]"
---

Audita el código de ML/IA en: $ARGUMENTS (si está vacío, los cambios de la rama actual contra `main`).

Elige como máximo 2 subagentes, los que más apliquen, y lánzalos en paralelo:

- `mle-reviewer`: datos, entrenamiento, evaluación, serving, monitoreo, rollback (opción por defecto).
- `rag-pipeline-reviewer`: si hay recuperación, embeddings o índices vectoriales.
- `auditor-seguridad`: si hay PII, deserialización (pickle/joblib), prompt injection o salidas del modelo que llegan a SQL/shell.

Si el cambio es chico (un script, un notebook, un ajuste de parámetros), no lances subagentes: revísalo tú contra `.claude/rules/ml-datos.md` y `.claude/rules/llm-apps.md`.

Entrega una lista priorizada (CRÍTICO, ALTO, MEDIO, BAJO) con `archivo:línea`, evidencia y arreglo, y un checklist de "listo para producción" con lo que falta: tests de datos, evals, umbrales, monitoreo, plan de rollback.

No modifiques código. Pregunta antes de aplicar arreglos.
