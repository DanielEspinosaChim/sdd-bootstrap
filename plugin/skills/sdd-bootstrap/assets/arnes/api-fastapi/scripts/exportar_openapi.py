#!/usr/bin/env python3
"""Documentación viva: exporta el contrato OpenAPI de la app a docs/api/openapi.json.

CI lo vuelve a generar y falla si el archivo commiteado quedó desactualizado,
así la documentación de la API nunca miente sobre el código.

Uso:  python scripts/exportar_openapi.py
"""

import json
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
sys.path[:0] = [str(RAIZ / "tests"), str(RAIZ / "src"), str(RAIZ)]

from arnes_config import cargar_app  # noqa: E402

destino = RAIZ / "docs" / "api" / "openapi.json"
destino.parent.mkdir(parents=True, exist_ok=True)
destino.write_text(
    json.dumps(cargar_app().openapi(), indent=2, sort_keys=True, ensure_ascii=False) + "\n",
    encoding="utf-8",
)
print(f"Escrito {destino.relative_to(RAIZ)}")
