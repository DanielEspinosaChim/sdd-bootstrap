# sdd-bootstrap

Spec-Driven Development para Claude Code, con un arnés de seguridad y calidad que ahorra tokens.

Le dices a Claude "monta mi proyecto con SDD" y te entrevista un tema a la vez: misión, stack, roadmap, MCPs, subagentes y seguridad. Con eso genera el proyecto completo y le instala un arnés que **la máquina hace cumplir**, no solo instrucciones que el modelo puede olvidar.

## Qué genera

- **Constitución:** `spec/constitution/` con misión, stack y roadmap ordenado.
- **Features:** `spec/features/NNN-*/` con `spec.md`, `plan.md` y `tasks.md`. Cada criterio de aceptación lleva un ID (`C001-3`) y su test.
- **Checklist de seguridad transversal:** 11 puntos, más 3 si el proyecto usa LLMs.
- **`CLAUDE.md`:** stack, comandos, reglas, proporcionalidad y qué significa "terminado".
- **Subagentes:** los 4 roles de SDD (`coordinador`, `implementador`, `tester`, `auditor-seguridad`).
- **`docs/`:** memoria de sesión que el agente actualiza solo.

## El arnés

| Capa | Qué hace |
| --- | --- |
| **Hooks** (casi no gastan tokens) | Bloquean `rm -rf`, push a main, `--force`, `reset --hard`, `--no-verify`, `sudo`, `curl \| bash`, lectura de `.env` y credenciales, borrado de bases de datos. Detectan secretos escritos en código. Corren Ruff al editar. No dejan terminar con tests rojos ni decir "listo" sin verificar. Piden confirmación si el agente debilita un test (quita asserts, marca skip o cambia un valor esperado ya commiteado). |
| **Pruebas automáticas por endpoint** (FastAPI) | Schemathesis prueba el contrato OpenAPI de **todos** los endpoints con datos válidos, inválidos y extremos. Además, toda ruta exige auth salvo las declaradas públicas, se rechazan credenciales falsas y no se filtran trazas. Un endpoint nuevo queda cubierto en cuanto existe. |
| **Trazabilidad y documentación viva** | Un script falla si un criterio de aceptación no tiene test. `docs/trazabilidad.md` y `docs/api/openapi.json` se regeneran en cada commit y CI falla si quedan desactualizados. |
| **pre-commit y CI** | Gitleaks, Semgrep, Trivy, pip-audit, tipos, cobertura ≥ 90 % de las líneas nuevas (diff-cover). |
| **Proporcionalidad** | Cambio chico: el agente principal solo, sin subagentes. Mediano o crítico: los 4 roles. Ante la duda, el nivel mayor. |

Paquetes opcionales: **dev** (comandos `/nueva-feature`, `/implementar`, `/revisar`, `/verificar`, `/pr`... y skills de método) e **ia** (datos, ML, LLMs, RAG, evals). La instalación ligera ocupa ~1,000 tokens de contexto por sesión; la completa, ~7,000.

## Instalación

### Claude Code, como plugin (recomendado)

```
/plugin marketplace add DanielEspinosaChim/sdd-bootstrap
/plugin install sdd-bootstrap@sdd-bootstrap
```

### Claude Code, a mano

Copia `plugin/skills/sdd-bootstrap/` a `~/.claude/skills/sdd-bootstrap/`.

### Claude (app y web)

Descarga `sdd-bootstrap.zip` de la sección [Releases](../../releases) y súbelo como skill en la configuración de Claude.

### Context7 y otros MCPs con tu cuenta

Ninguna API key va en el repo. Cada conector lee su credencial de una variable de entorno (`CONTEXT7_API_KEY`, `GITHUB_TOKEN`, `DATABASE_URL`...). La skill te pregunta si quieres cada MCP en todos tus proyectos (alcance de usuario) o solo en uno, y te da el comando para configurarlo. Para Context7:

```
# Windows (PowerShell): guarda la key sin mostrarla ni dejarla en el historial
$s = Read-Host "API key de Context7" -AsSecureString; [Environment]::SetEnvironmentVariable("CONTEXT7_API_KEY", [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)), "User")
claude mcp add --scope user context7 -- cmd /c npx -y @upstash/context7-mcp@4.4.1

# macOS / Linux: agrega export CONTEXT7_API_KEY=... a ~/.zshrc o ~/.bashrc, y luego
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@4.4.1
```

Reinicia Claude Code y comprueba con `claude mcp list`.

### Requisitos en tus proyectos

`git`, `jq` (los hooks lo necesitan) y `pre-commit`. Recomendado: `uv` para Python. En Windows, los hooks corren con Git Bash, que viene con Git for Windows.

```
# macOS
brew install jq pre-commit uv
# Windows
winget install jqlang.jq ; winget install astral-sh.uv ; uv tool install pre-commit
```

## Uso

En Claude Code, dentro de la carpeta del proyecto (nuevo o existente):

> monta mi proyecto con SDD

Luego construye cada feature con `/implementar spec/features/001-...` y agrega nuevas con `/nueva-feature`.

## Probado

- Claude Code real: la skill completa generada en un proyecto de ML y en una API multi-tenant. Bloqueos de push a main, `rm -rf` y `.env` confirmados en vivo, igual que el guardrail que impide debilitar tests.
- `scripts/test-hooks.sh`: 49 de 49 casos.
- Pruebas por endpoint: con tres errores plantados (ruta sin auth, división entre cero, traza filtrada), las tres los detectan sin código específico.
- Sin probar: Gitleaks y Semgrep en pre-commit, y los workflows corriendo en GitHub Actions.

## Límites

- Las pruebas por endpoint solo existen para FastAPI. Con otros frameworks se instalan la trazabilidad y la cobertura, pero no estas.
- Las pruebas automáticas no detectan errores de lógica de negocio ni fugas entre tenants. Eso lo cubren los tests por criterio y el tester y el auditor de seguridad.
- La proporcionalidad y `docs/` son instrucciones en `CLAUDE.md`, no bloqueos.

## Créditos

Construido sobre trabajo abierto de otros; ver [NOTICE.md](NOTICE.md).
