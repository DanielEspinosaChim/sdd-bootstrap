#!/usr/bin/env bash
# instalar-arnes.sh — Instala el arnés (seguridad, verificación, flujo y especialistas) en un proyecto.
# Lo llama la skill sdd-bootstrap después de generar spec/, CLAUDE.md y docs/. No crea CLAUDE.md
# ni spec/ (eso lo hace la skill) y nunca pisa archivos existentes.
#
# Uso:
#   bash instalar-arnes.sh --destino RUTA [--stack python|node|ambos] [--paquetes dev,ia]
#                          [--nivel ligero|completo] [--ci si|no] [--claude-github si|no] [--llm si|no]
#                          [--api fastapi --app paquete.modulo:app]
#
#   --stack          python (defecto), node o ambos: decide reglas, Ruff y el workflow de CI.
#   --paquetes       además de base (siempre): dev, ia o dev,ia. Defecto: dev.
#   --nivel          ligero (defecto): solo lo esencial, menos contexto por sesión.
#                    completo: todos los especialistas y skills del paquete.
#   --ci             si (defecto): workflow de CI con tests, lint, Gitleaks, Semgrep y Trivy.
#   --claude-github  no (defecto): @claude en issues, revisión automática de PRs y auto-arreglo
#                    de CI. Cada corrida gasta tokens de API; actívalo cuando lo quieras.
#   --llm            no (defecto): con el paquete ia, agrega lo específico de LLMs (RAG, evals,
#                    prompts). Úsalo si el proyecto llama a modelos de lenguaje.
#   --api fastapi    agrega pruebas automáticas a TODOS los endpoints (contrato con Schemathesis y
#                    seguridad: auth obligatoria, credenciales falsas, fugas de detalles) y exporta el
#                    OpenAPI a docs/api/ como documentación viva. Requiere --app.
set -euo pipefail

SKILL="$(cd "$(dirname "$0")/.." && pwd)"
A="$SKILL/assets/arnes"
# La versión para la app de Claude trae los paquetes dev e ia empaquetados en un .tar.gz
# (la app limita los skills a 200 archivos). Se extraen a una carpeta temporal.
if [ ! -d "$A/base/.claude" ] && [ -f "$SKILL/assets/arnes.tar.gz" ]; then
  # La app de Claude descarta archivos ocultos (.claude, .github...) al subir la skill:
  # en esa versión todo el arnés viene dentro de arnes.tar.gz.
  TMPA=$(mktemp -d)
  trap 'rm -rf "$TMPA"' EXIT
  tar -xzf "$SKILL/assets/arnes.tar.gz" -C "$TMPA"
  A="$TMPA/arnes"
elif [ ! -d "$A/dev" ] && [ -f "$SKILL/assets/arnes-paquetes.tar.gz" ]; then
  TMPA=$(mktemp -d)
  trap 'rm -rf "$TMPA"' EXIT
  cp -R "$A" "$TMPA/arnes"
  tar -xzf "$SKILL/assets/arnes-paquetes.tar.gz" -C "$TMPA/arnes"
  A="$TMPA/arnes"
fi
DEST=""; STACK="python"; PAQ="dev"; NIVEL="ligero"; CI="si"; CGH="no"; LLM="no"; API=""; APPREF=""
while [ $# -gt 0 ]; do
  case "$1" in
    --destino) DEST="$2"; shift 2 ;;
    --stack) STACK="$2"; shift 2 ;;
    --paquetes) PAQ="$2"; shift 2 ;;
    --nivel) NIVEL="$2"; shift 2 ;;
    --ci) CI="$2"; shift 2 ;;
    --claude-github) CGH="$2"; shift 2 ;;
    --llm) LLM="$2"; shift 2 ;;
    --api) API="$2"; shift 2 ;;
    --app) APPREF="$2"; shift 2 ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "Opción desconocida: $1"; exit 1 ;;
  esac
done
[ -n "$DEST" ] && [ -d "$DEST" ] || { echo "Falta --destino con una carpeta existente"; exit 1; }
DEST="$(cd "$DEST" && pwd)"
case "$STACK" in python|node|ambos) ;; *) echo "--stack: python, node o ambos"; exit 1 ;; esac
case "$NIVEL" in ligero|completo) ;; *) echo "--nivel: ligero o completo"; exit 1 ;; esac
if [ -n "$API" ]; then
  [ "$API" = fastapi ] || { echo "--api: por ahora solo fastapi"; exit 1; }
  [[ "$APPREF" == *:* ]] || { echo "--api fastapi requiere --app paquete.modulo:variable (ej. miapp.main:app)"; exit 1; }
fi
command -v jq >/dev/null || { echo "Falta jq (los hooks lo necesitan): brew install jq / apt install jq"; exit 1; }

PY=0; NODE=0
[ "$STACK" = python ] || [ "$STACK" = ambos ] && PY=1
[ "$STACK" = node ] || [ "$STACK" = ambos ] && NODE=1
has() { [[ ",$PAQ," == *",$1,"* ]]; }

LISTA=()
add() { LISTA+=("$@"); }   # rutas relativas a $A (archivos o carpetas)

# ---------- base (siempre) ----------
add base/.claude/settings.json base/.claude/hooks base/scripts/test-hooks.sh base/scripts/trazabilidad.py \
    base/.claude/rules/revision.md \
    base/.pre-commit-config.yaml
[ $PY = 1 ] && add base/.claude/rules/python.md base/ruff.toml base/.claude/agents/python-reviewer.md
[ $NODE = 1 ] && add base/.claude/agents/code-reviewer.md
[ "$NIVEL" = completo ] && add base/.claude/agents/code-reviewer.md base/.claude/agents/silent-failure-hunter.md base/.claude/agents/security-reviewer.md base/.claude/agents/verifier.md
if [ "$CI" = si ]; then
  [ $PY = 1 ] && add base/.github/workflows/ci-python.yml
  [ $NODE = 1 ] && [ $PY = 0 ] && add base/.github/workflows/ci-node.yml
  [ $NODE = 1 ] && [ $PY = 1 ] && echo "  Aviso: stack mixto; se instala ci-python.yml. Copia ci-node.yml a mano si lo necesitas."
fi
[ "$CGH" = si ] && add base/.github/workflows/claude.yml base/.github/workflows/claude-review.yml base/.github/workflows/claude-fix-ci.yml

# ---------- dev ----------
if has dev; then
  add dev/.claude/commands
  if [ "$NIVEL" = completo ]; then
    add dev/.claude/agents dev/.claude/skills
  else
    for s in test-driven-development systematic-debugging verification-before-completion writing-plans executing-plans; do
      add "dev/.claude/skills/$s"
    done
    [ $PY = 1 ] && add dev/.claude/skills/python-testing
  fi
  [ $NODE = 1 ] && add dev/.claude/rules/stacks
fi

# ---------- ia ----------
if has ia; then
  add ia/.claude/rules/ml-datos.md ia/.claude/commands/experimento.md ia/.claude/commands/auditar-modelo.md
  [ "$LLM" = si ] && add ia/.claude/rules/llm-apps.md ia/.claude/commands/evaluar-llm.md
  if [ "$NIVEL" = completo ]; then
    add ia/.claude/agents ia/.claude/skills ia/.claude/rules ia/.claude/commands
  else
    add ia/.claude/agents/mle-reviewer.md ia/.claude/skills/mle-workflow
    [ "$LLM" = si ] && add ia/.claude/agents/rag-pipeline-reviewer.md ia/.claude/skills/llm-evaluation
  fi
fi

# ---------- pruebas automáticas por endpoint ----------
[ "$API" = fastapi ] && add api-fastapi/tests api-fastapi/scripts

# ---------- copiar sin pisar ----------
NUEVOS=0; EXIST=0
copiar_archivo() {  # $1 = ruta absoluta en $A
  local rel="${1#"$A"/}"; rel="${rel#*/}"   # quita el prefijo del módulo (base/, dev/, ia/)
  local dst="$DEST/$rel"
  if [ -e "$dst" ]; then EXIST=$((EXIST+1)); else mkdir -p "$(dirname "$dst")"; cp -p "$1" "$dst"; NUEVOS=$((NUEVOS+1)); fi
}
for item in "${LISTA[@]}"; do
  src="$A/$item"
  [ -e "$src" ] || { echo "  (no existe en el kit: $item)"; continue; }
  if [ -d "$src" ]; then
    while IFS= read -r -d '' f; do copiar_archivo "$f"; done < <(find "$src" -type f -print0)
  else
    copiar_archivo "$src"
  fi
done
mkdir -p "$DEST/.claude/licencias-terceros"
for f in "$A"/licencias/*; do [ -e "$DEST/.claude/licencias-terceros/$(basename "$f")" ] || cp "$f" "$DEST/.claude/licencias-terceros/"; done
chmod +x "$DEST"/.claude/hooks/*.sh "$DEST/scripts/test-hooks.sh" "$DEST/scripts/trazabilidad.py"
if [ "$API" = fastapi ] && grep -q '{{APP}}' "$DEST/tests/arnes_config.py" 2>/dev/null; then
  sed -i.bak "s|{{APP}}|$APPREF|" "$DEST/tests/arnes_config.py" && rm -f "$DEST/tests/arnes_config.py.bak"
fi
find "$DEST/.claude/skills" -path '*/scripts/*' -type f -exec chmod +x {} + 2>/dev/null || true

# ---------- .gitignore ----------
touch "$DEST/.gitignore"
IGN=(".env" ".env.*" "!.env.example" ".claude/settings.local.json" "CLAUDE.local.md" ".trash/" ".superpowers/")
has ia && IGN+=("data/" "*.pkl" "*.joblib" "*.ckpt" "*.safetensors" "mlruns/" "wandb/")
[ $NODE = 1 ] && IGN+=("node_modules/")
for line in "${IGN[@]}"; do grep -qxF "$line" "$DEST/.gitignore" || echo "$line" >> "$DEST/.gitignore"; done

# ---------- probar guards ----------
RES=$(cd "$DEST" && bash scripts/test-hooks.sh | tail -1) || { echo "FALLA: algún guard no bloquea lo esperado. Corre: bash scripts/test-hooks.sh"; exit 1; }

if command -v pre-commit >/dev/null && [ -d "$DEST/.git" ]; then (cd "$DEST" && pre-commit install >/dev/null) && PC="activado"; else PC="no activado (instala pre-commit y corre: pre-commit install)"; fi

cuenta() { { ls "$DEST/.claude/$1" 2>/dev/null || true; } | wc -l | tr -d ' '; }
echo "Arnés instalado (stack=$STACK, paquetes=base,$PAQ, nivel=$NIVEL, llm=$LLM, ci=$CI, claude-github=$CGH)"
echo "  $NUEVOS archivos nuevos, $EXIST ya existían y no se tocaron"
echo "  subagentes: $(cuenta agents) · skills: $(cuenta skills) · comandos: $(cuenta commands) · hooks: 9"
echo "  guards: $RES"
echo "  pre-commit: $PC"
if [ "$API" = fastapi ]; then
  echo "  pruebas por endpoint: tests/test_contrato_api.py y tests/test_seguridad_endpoints.py (app: $APPREF)"
  echo "  dependencias de desarrollo que necesitan (agrégalas con aviso al usuario):"
  echo "    uv add --dev pytest pytest-cov schemathesis httpx"
  echo "  ajusta CREDENCIALES_PRUEBA y RUTAS_PUBLICAS en tests/arnes_config.py; documenta 400/401/403 en la app"
fi
