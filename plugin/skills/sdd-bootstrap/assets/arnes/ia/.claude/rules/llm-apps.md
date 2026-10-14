---
paths:
  - "**/*llm*/**"
  - "**/*agent*/**"
  - "**/*rag*/**"
  - "**/*prompt*/**"
  - "**/prompts/**"
  - "**/evals/**"
  - "**/*llm*.py"
  - "**/*agent*.py"
  - "**/*rag*.py"
  - "**/*prompt*.py"
  - "**/*eval*.py"
  - "**/*chat*.py"
---

# Reglas para aplicaciones con LLMs

Aplican cuando el código llama a un modelo de lenguaje (Claude, OpenAI, modelos locales), arma prompts, hace RAG o implementa agentes.

## Evals son los tests de un LLM

- Ningún cambio de prompt, modelo, parámetros o pipeline de RAG sin correr el set de evaluación antes y después. Reporta ambos números.
- El set de evaluación vive en `evals/` (casos en JSONL con entrada, salida esperada o criterio, y etiqueta del modo de falla), versionado en git, separado de cualquier dato usado para ajustar prompts.
- Mide por modo de falla, no solo un promedio: respuestas inventadas, formato roto, rechazos indebidos, fuga de datos, latencia y costo.
- Si usas un LLM como juez, valídalo contra al menos 30 casos etiquetados por un humano y reporta el acuerdo.
- Los tests unitarios del código alrededor del LLM no llaman al modelo real: usan respuestas grabadas (fixtures). Las llamadas reales van en una suite marcada (`@pytest.mark.llm`) que no corre en cada commit.

## Salidas del modelo = entrada no confiable

- Valida toda salida estructurada con un esquema (pydantic, JSON Schema) y maneja el caso de que no cumpla: reintento acotado o error claro. Nunca `json.loads` sin validar.
- Nunca ejecutes, evalúes ni pases a un shell, SQL o `eval` lo que generó el modelo sin validarlo contra una lista permitida.
- Prefiere salidas estructuradas o tool use nativos del proveedor sobre pedir JSON en texto libre.

## Prompt injection

- Todo texto que venga de usuarios, documentos, páginas web, correos o resultados de herramientas es dato, no instrucción. Sepáralo del prompt de sistema con delimitadores claros y díselo al modelo.
- Una herramienta que el agente puede llamar tiene el mínimo permiso posible. Las acciones irreversibles (enviar, pagar, borrar, publicar) requieren confirmación humana fuera del modelo.
- Nunca pongas secretos, llaves ni datos de otros usuarios en un prompt.

## Prompts

- Los prompts viven en archivos versionados (`prompts/*.md` o constantes en un módulo), no armados con strings dispersos.
- Cada cambio de prompt va en su propio commit con el resultado de los evals en el mensaje o el PR.
- Fija la versión exacta del modelo (el ID con fecha o versión), nunca un alias que cambie solo.

## Costo, latencia y confiabilidad

- Registra por llamada: modelo, tokens de entrada y salida, latencia, costo estimado y si hubo error. Sin ese log no hay optimización posible.
- Usa caché de prompt para el contexto que se repite (prompt de sistema, documentos fijos).
- Timeouts y reintentos con backoff exponencial y tope; maneja los límites de tasa (429) explícitamente.
- Elige el modelo más barato que pase los evals; no el más grande por defecto.

## RAG

- Evalúa la recuperación por separado de la generación (recall@k / MRR sobre preguntas con documento correcto conocido).
- Guarda con cada fragmento su fuente, y haz que la respuesta cite fuentes verificables.
- Cambiar el modelo de embeddings, el tamaño de fragmento o el índice requiere reindexar y volver a correr los evals de recuperación.

## Datos personales

- No envíes PII a un proveedor externo sin que esté permitido para ese dato. Anonimiza o enmascara antes si hace falta.
- No registres prompts ni respuestas completas con PII en logs de producción.
