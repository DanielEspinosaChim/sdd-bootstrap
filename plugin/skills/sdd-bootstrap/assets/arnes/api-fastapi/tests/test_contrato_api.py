"""Pruebas de contrato generadas automáticamente para cada endpoint (Schemathesis).

Schemathesis lee el OpenAPI de la app y genera, por cada endpoint, entradas
válidas, inválidas y extremas. Falla si un endpoint responde 500, si la
respuesta no cumple el esquema documentado, si devuelve códigos de estado no
documentados, si ignora la autenticación o si filtra detalles internos.

Requisito para que pase: documentar en la app las respuestas de error comunes,
p. ej. FastAPI(responses={400: {...}, 401: {...}, 403: {...}}).
"""

import re

import pytest
import schemathesis
from arnes_config import CASOS_POR_ENDPOINT, CREDENCIALES_PRUEBA, cargar_app
from hypothesis import HealthCheck, settings

APP = cargar_app()
FUGAS = re.compile(
    r"Traceback \(most recent call last\)|File \"/|site-packages|sqlalchemy\.|psycopg"
)


@schemathesis.check
def no_filtra_detalles_internos(ctx, response, case) -> None:
    """Ninguna respuesta incluye trazas, rutas de archivos ni errores de BD."""
    if FUGAS.search(response.text or ""):
        raise AssertionError(f"La respuesta de {case.method} {case.path} filtra detalles internos")


@schemathesis.auth()
class CredencialesDePrueba:
    """Pone las credenciales de prueba en cada llamada.

    Schemathesis prueba aparte la llamada sin credenciales.
    """

    def get(self, case, ctx):
        return CREDENCIALES_PRUEBA

    def set(self, case, data, ctx) -> None:
        case.headers = {**(case.headers or {}), **data}


if APP is None:

    @pytest.mark.skip(reason="La app aún no existe (ver APP en tests/arnes_config.py)")
    def test_contrato_api() -> None:
        pass

else:
    schema = schemathesis.openapi.from_asgi("/openapi.json", APP)

    @schema.parametrize()
    @settings(
        max_examples=CASOS_POR_ENDPOINT, deadline=None, suppress_health_check=list(HealthCheck)
    )
    def test_contrato_api(case) -> None:
        case.call_and_validate()
