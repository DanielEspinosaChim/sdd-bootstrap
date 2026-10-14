---
paths:
  - "**/*.py"
  - "**/*.ipynb"
  - "**/*.sql"
  - "**/data/**"
  - "**/models/**"
  - "**/notebooks/**"
---

# Reglas para código de datos y ML

## Datos

- Nunca leas datasets completos en el contexto. Usa `df.head()`, `df.shape`, `df.dtypes`, `df.describe()` o muestras de máximo 20 filas.
- Nunca subas datos crudos, dumps ni datos con PII a git. Van en `data/` (en `.gitignore`) o en almacenamiento externo.
- Valida el esquema de entrada en la frontera (al cargar): columnas, tipos, rangos y nulos. Falla con un error claro, no sigas con datos malos.
- No modifiques archivos en `data/raw/`. Todo dato derivado se genera con código reproducible.

## Fuga de datos (leakage)

- Separa train / validación / test antes de cualquier ajuste (escaladores, imputadores, encoders, selección de features). Ajusta solo con train.
- En series de tiempo, el split es por fecha. Nunca uses aleatorio.
- Si un feature usa información posterior al momento de la predicción, es fuga. Señálalo aunque mejore la métrica.

## Reproducibilidad

- Fija semillas (`random`, `numpy`, framework) y regístralas junto al experimento.
- Fija versiones exactas de dependencias.
- Cada métrica reportada dice: dataset, split, versión del código y semilla.

## Tests de ML (además de los unitarios)

- Test de esquema del dataset de entrada.
- Test de que el pipeline corre de punta a punta con un fixture pequeño (menos de 1 segundo).
- Test de umbral: la métrica en un set fijo de referencia no baja de un mínimo acordado.
- Test de forma de salida: shape, dtype y rango de las predicciones.

## Modelos

- Nunca cargues con `pickle`/`joblib` artefactos de fuentes no confiables (ejecutan código). Prefiere `safetensors`, ONNX o formatos sin ejecución.
- No cambies hiperparámetros, el split o la métrica objetivo sin decirlo explícitamente en el resumen.

## Notebooks

- La lógica reutilizable vive en módulos `.py` con tests; el notebook solo la llama.
- Limpia outputs antes de commitear (`nbstripout`).
