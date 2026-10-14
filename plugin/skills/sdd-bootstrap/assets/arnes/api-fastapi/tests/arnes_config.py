"""Configuración de las pruebas automáticas por endpoint del arnés.

Es el único archivo que se ajusta por proyecto. test_contrato_api.py y
test_seguridad_endpoints.py lo leen y aplican sus pruebas a TODOS los
endpoints de la app, incluidos los que se agreguen después.
"""

import importlib

# Dónde está la app FastAPI: "paquete.modulo:variable".
APP = "{{APP}}"

# Rutas que de verdad son públicas (sin autenticación). Toda ruta que no esté
# aquí debe responder 401 o 403 si llega sin credenciales. Agregar una ruta a
# esta lista es una decisión de seguridad: hazla explícita en el PR.
RUTAS_PUBLICAS: set[tuple[str, str]] = {
    ("GET", "/health"),
    ("GET", "/openapi.json"),
    ("GET", "/docs"),
    ("GET", "/docs/oauth2-redirect"),
    ("GET", "/redoc"),
}

# Encabezados con credenciales válidas de PRUEBA (nunca credenciales reales).
# Ajusta al esquema de auth del proyecto, p. ej. {"Authorization": "Bearer <token-de-prueba>"}.
CREDENCIALES_PRUEBA: dict[str, str] = {"Authorization": "Bearer token-de-prueba"}

# Cuántos casos genera Schemathesis por endpoint. Más casos = más tiempo.
CASOS_POR_ENDPOINT = 50


def cargar_app():
    """Devuelve la app indicada en APP, o None si todavía no existe."""
    modulo, _, variable = APP.partition(":")
    try:
        return getattr(importlib.import_module(modulo), variable)
    except (ModuleNotFoundError, AttributeError):
        return None
