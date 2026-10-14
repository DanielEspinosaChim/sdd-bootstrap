---
paths:
  - "**/*.py"
  - "**/*.pyi"
  - "**/*.ipynb"
  - "**/pyproject.toml"
  - "**/uv.lock"
---

# Python

## Herramientas

| Para | Usa | No uses |
| --- | --- | --- |
| Dependencias y entorno | `uv` (`uv add`, `uv sync`, `uv run`) | pip suelto, poetry, `pip install --break-system-packages` |
| Lint y formato | `ruff check` · `ruff format` | black, isort, flake8, pylint |
| Tipos | `mypy` (o `ty` si el proyecto ya lo usa) | — |
| Tests | `pytest` | unittest para código nuevo |
| Auditoría de dependencias | `uv run pip-audit` | — |

Corre todo con `uv run ...`, nunca con un `python3` suelto fuera del entorno del proyecto.

## Límites en la configuración, no en prosa

La complejidad, el número de argumentos y el largo de funciones los hace cumplir ruff (ver `pyproject.toml`). Si ruff se queja, arregla el código; no subas los límites sin decirlo en el PR.

## Estilo

- Anotaciones de tipo en todas las firmas públicas.
- Imports absolutos; sin imports relativos.
- `pathlib.Path` en vez de rutas como strings.
- `logging` en vez de `print` en código de librería o servicio.
- Errores específicos: nunca `except:` ni `except Exception: pass`. Si atrapas, registra o relanza con contexto.
- Dataclasses o modelos de pydantic para estructuras de datos en las fronteras.

## Tests

- Viven en `tests/`, espejo de la estructura del paquete.
- Nombres que describen el comportamiento: `test_devuelve_vacio_si_no_hay_coincidencias`.
- Estructura Arrange / Act / Assert.
- `pytest.mark.parametrize` para casos borde en vez de copiar tests.
- Fixtures pequeñas y deterministas; nada de red ni de datos reales en tests unitarios.

## Cadena de suministro

- Versiones exactas en el lockfile (`uv.lock` va a git).
- Antes de agregar un paquete: confirma que existe con ese nombre exacto en PyPI, que está mantenido y que no es un nombre parecido a uno popular (typosquatting).
- `pip-audit` antes de desplegar.
