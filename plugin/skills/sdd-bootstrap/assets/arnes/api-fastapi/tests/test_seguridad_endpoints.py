"""Pruebas de seguridad que se aplican solas a cada endpoint de la app.

No hay que escribir una prueba por endpoint: estas recorren todas las rutas,
así que un endpoint nuevo queda cubierto en cuanto existe. Si una falla, el
mensaje dice qué ruta y por qué.
"""

import re

import pytest
from arnes_config import CREDENCIALES_PRUEBA, RUTAS_PUBLICAS, cargar_app
from fastapi.routing import APIRoute
from fastapi.testclient import TestClient

APP = cargar_app()
pytestmark = pytest.mark.skipif(
    APP is None, reason="La app aún no existe (ver APP en tests/arnes_config.py)"
)

# Señales de que una respuesta filtra detalles internos.
FUGAS = re.compile(
    r"Traceback \(most recent call last\)|File \"/|site-packages|"
    r"sqlalchemy\.|psycopg|IntegrityError|ProgrammingError|"
    r"at [\w.$]+\([\w.]+:\d+\)",
)


def _rutas() -> list[tuple[str, str]]:
    if APP is None:
        return []
    return [
        (metodo, ruta.path)
        for ruta in APP.routes
        if isinstance(ruta, APIRoute)
        for metodo in sorted(ruta.methods - {"HEAD", "OPTIONS"})
    ]


def _url(path: str, relleno: str = "1") -> str:
    return re.sub(r"\{[^}]+\}", relleno, path)


RUTAS = _rutas()
PROTEGIDAS = [r for r in RUTAS if r not in RUTAS_PUBLICAS]


@pytest.fixture(scope="module")
def cliente() -> TestClient:
    return TestClient(APP, raise_server_exceptions=False)


@pytest.mark.parametrize(("metodo", "path"), PROTEGIDAS, ids=[f"{m} {p}" for m, p in PROTEGIDAS])
def test_ruta_exige_autenticacion(cliente: TestClient, metodo: str, path: str) -> None:
    """Toda ruta no pública responde 401/403 sin credenciales."""
    respuesta = cliente.request(metodo, _url(path), json={})
    assert respuesta.status_code in (401, 403), (
        f"{metodo} {path} respondió {respuesta.status_code} sin credenciales. "
        "Protégela o, si de verdad es pública, agrégala a RUTAS_PUBLICAS en tests/arnes_config.py."
    )


@pytest.mark.parametrize(("metodo", "path"), PROTEGIDAS, ids=[f"{m} {p}" for m, p in PROTEGIDAS])
def test_credenciales_falsas_rechazadas(cliente: TestClient, metodo: str, path: str) -> None:
    """Credenciales con el formato correcto pero falsas también se rechazan."""
    falsas = {
        k: (v.split(" ")[0] + " credencial-falsa-123" if " " in v else "credencial-falsa-123")
        for k, v in CREDENCIALES_PRUEBA.items()
    }
    respuesta = cliente.request(metodo, _url(path), headers=falsas, json={})
    assert respuesta.status_code in (401, 403), f"{metodo} {path} aceptó credenciales falsas"


@pytest.mark.parametrize(("metodo", "path"), RUTAS, ids=[f"{m} {p}" for m, p in RUTAS])
def test_errores_no_filtran_detalles(cliente: TestClient, metodo: str, path: str) -> None:
    """Con entradas maliciosas o basura, no hay 500 ni se filtran trazas o detalles de BD."""
    basura = {"__x": "' OR 1=1 --", "n": -(10**18), "s": "\x00\x00<script>alert(1)</script>"}
    url = _url(path, "%27%20OR%201%3D1--")
    respuesta = cliente.request(metodo, url, headers=CREDENCIALES_PRUEBA, json=basura)
    assert respuesta.status_code < 500, (
        f"{metodo} {path} respondió {respuesta.status_code} con entrada inválida"
    )
    assert not FUGAS.search(respuesta.text), (
        f"{metodo} {path} filtra detalles internos en la respuesta"
    )
