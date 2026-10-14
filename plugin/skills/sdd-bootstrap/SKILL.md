---
name: sdd-bootstrap
description: Use this skill whenever the user wants to set up a new software project (or retrofit an existing one) with Spec-Driven Development. It runs a conversational interview (mission, stack, roadmap, MCPs, subagents, security checklist, first feature specs), generates the scaffold (spec/constitution/, CLAUDE.md, MCP config, subagents, docs/, spec/features/) and installs a token-efficient safety harness (hooks, permissions, pre-commit, CI, workflow commands, optional dev and AI/ML packs). Trigger on phrases like "monta mi proyecto con SDD", "configúrame todo el flujo de agentes", "arranca un proyecto nuevo con specs", "hazme las preguntas para armar el proyecto", "quiero implementar spec-driven development", "ponle el arnés a mi proyecto", or when the user wants Claude Code fully configured from zero without a defined mission, roadmap or stack. Also use it mid-project to add a missing harness, guardrails, subagents or security checklist.
---

# SDD Bootstrap — entrevista guiada + generación completa del scaffold + arnés

Esta skill convierte una plática con el usuario en el andamiaje completo de
Spec-Driven Development: constitución, arnés (CLAUDE.md), MCPs, subagentes,
checklist de seguridad y las primeras specs de feature — listo para empezar
a implementar. Además instala un arnés de seguridad y verificación que la
máquina hace cumplir (hooks, permisos, pre-commit, CI) y, según el
proyecto, los paquetes de desarrollo y de IA/ML.

No es un formulario. Es una conversación, un tema a la vez, con criterio
propio: si el usuario da una respuesta genérica, se le insiste con opciones
concretas antes de aceptarla.

## Principio central: entrevistar bien, no solo preguntar

- **Un tema a la vez.** Nunca sueltes las 7 preguntas juntas. Pregunta,
  espera la respuesta, reacciona en una línea, sigue.
- **No aceptes respuestas genéricas sin insistir.** Si el usuario dice "una
  app normal", "lo que tú creas mejor", "no sé, decide tú" en la primera
  pasada, no lo tomes como respuesta final. Ofrécele 2-4 opciones concretas
  construidas sobre lo que ya dijo, y pídele que elija o corrija. Solo si
  insiste en "decide tú" después de ver opciones concretas, usa un default
  razonable y márcalo con `<!-- REVISAR -->` en el archivo generado.
- **No inventes decisiones de negocio** (audiencia, monetización,
  cumplimiento normativo) sin confirmar. **Sí puedes proponer** decisiones
  técnicas concretas (stack, testing) porque son fáciles de corregir después
  — pero siempre como propuesta a confirmar, no como hecho consumado.
- **Cierra cada tema con un resumen de una línea** antes de pasar al
  siguiente, para que el usuario sienta que va avanzando y pueda corregir
  sobre la marcha.
- Si en cualquier momento el usuario pide saltarse pasos o ya trae la info
  lista (p. ej. pega su stack y roadmap de un jalón), no repitas preguntas
  que ya respondió — solo rellena huecos.

## Principio de economía: seguro y rápido, sin gastar de más

El proyecto que sale de esta skill debe ser seguro **y** barato de operar.

- **La seguridad la ponen los hooks, no los subagentes.** Los hooks son
  scripts: bloquean lo peligroso y corren lint y tests sin gastar tokens.
  Los subagentes cuestan contexto y tiempo; se reservan para lo que paga.
- **Esfuerzo proporcional al riesgo.** Cada spec declara su nivel (Chico /
  Mediano / Crítico) y eso decide cuánta revisión lleva. Un endpoint
  básico no se valida con cinco agentes. Ver "Proporcionalidad" en
  `references/sdd-fundamentals.md`.
- **Instalación ligera por defecto.** Solo los especialistas y skills que
  el stack necesita (cada descripción ocupa contexto en cada sesión). El
  nivel completo se instala solo si el usuario lo pide.
- **Durante la entrevista, tampoco gastes:** no lances subagentes, no leas
  todo el repo si basta con los manifiestos y el README, y escribe cada
  archivo una sola vez.

## Paso 0 — Detectar punto de partida

Pregunta primero: **¿Es un proyecto nuevo o ya existe código?**

- **Si ya existe código:** antes de preguntar nada más, lee tú mismo el
  repo (package.json / requirements.txt / pyproject.toml / README / entry
  points principales). Infiere stack, estructura y de qué trata el
  proyecto. Preséntale al usuario lo que dedujiste ("Veo que es un backend
  en FastAPI con PostgreSQL, ¿es correcto?") y solo pregunta lo que no
  pudiste inferir (misión real, roadmap futuro, subagentes deseados).
  Revisa también si ya tiene `.claude/`, `CLAUDE.md`, pre-commit o CI: el
  instalador del arnés no pisa nada, pero avisa qué ya existía.
- **Si es nuevo:** sigue la entrevista completa de abajo, en orden.

## Paso 1 — Misión

Pregunta: *"¿Qué vas a construir y para quién? Cuéntamelo como si se lo
explicaras a un amigo, no hace falta que esté pulido."*

- Si la respuesta es vaga ("una plataforma para gestionar cosas"), no la
  aceptes: ofrece opciones concretas, ej. *"¿Es más parecido a (A) un
  gestor de tareas interno para tu equipo, (B) una plataforma para
  clientes externos, (C) una herramienta de datos/reportes, o (D) otra
  cosa muy distinta?"*
- Pregunta de seguimiento hasta tener: **qué es**, **para quién** (usuario
  final), **qué problema le resuelve**, y si aplica, **qué lo hace
  distinto**.
- Toma nota, sin preguntar aparte, de si la misión implica **datos, ML o
  LLMs** (modelos, predicciones, RAG, chatbots, agentes, pipelines de
  datos). Eso decide si se instala el paquete de IA (paso 5), y si además
  usa modelos de lenguaje, su parte de LLMs (`--llm si`); un modelo
  clásico de ML no la necesita.
- Cierra con un resumen de una frase y pasa al siguiente tema.

## Paso 2 — Tech stack

Pregunta: *"¿Ya tienes el stack decidido, o quieres que te proponga uno
según lo que me describiste?"*

- Si ya lo tiene: captura lenguaje, framework/runtime, base de datos,
  framework de tests.
- Si no lo tiene: **propón un stack concreto** (no una lista genérica de
  opciones) basado en la misión, y pide confirmación. Ej.: *"Para esto te
  propondría TypeScript + Next.js + PostgreSQL (Prisma) + Vitest. ¿Te
  sirve o prefieres otra cosa (Python/FastAPI, otro frontend, etc.)?"*
- Captura también los **comandos de verificación** (tests, lint, tipos):
  son lo que define "terminado" en `CLAUDE.md` y lo que corren los hooks.
  En un proyecto Python propón `uv` + `pytest` + `ruff` + `mypy` si no hay
  otra preferencia.
- Si el proyecto expone una **API HTTP en FastAPI**, anota el módulo de la
  app (ej. `miapp.main:app`), el esquema de autenticación y qué rutas son
  públicas: con eso el arnés instala pruebas automáticas de contrato y
  seguridad para **todos** los endpoints (`--api fastapi --app ...`). Para
  otros frameworks esas pruebas no se instalan; la trazabilidad y la
  cobertura sí.
- Nunca dejes el tech-stack.md final con placeholders sin rellenar —
  o hay una decisión real, o hay un `<!-- REVISAR -->` explícito.

## Paso 3 — Roadmap

Pregunta: *"Dime todas las funcionalidades que se te ocurran, sin orden ni
filtro — un brain dump. Yo las organizo después."*

- Tú te encargas de **ordenarlas** en una secuencia lógica de construcción
  (lo que otras features dependen va primero; MVP antes que
  nice-to-haves). Muéstrale el roadmap ya ordenado antes de escribir el
  archivo, y pide su OK o ajustes.
- Si la lista que da es muy corta (1-2 items) para la misión que describió,
  **sugiere proactivamente 3-5 features típicas** de un proyecto así,
  claramente marcadas como sugerencia tuya, y pregunta cuáles incluir. No
  dejes que el roadmap quede incompleto por falta de iniciativa tuya.

## Paso 4 — MCPs

Pregunta: *"¿Configuro Context7 para tener siempre documentación
actualizada? Te lo recomiendo por default."* Después: *"¿Necesitas algún
otro MCP — GitHub, base de datos, Figma, Slack, etc.? Dime cuáles o dime
que por ahora no."*

- Solo configura lo que el usuario confirme explícitamente. No instales
  MCPs de forma especulativa "por si acaso".
- **Context7 con la cuenta del usuario, en todos sus proyectos.** Si dice
  que sí, pregunta una vez si tiene API key de Context7 (de
  context7.com/dashboard; sin key también funciona, con límites más bajos).
  La key **nunca** se escribe en un archivo del proyecto ni se pide pegada
  en el chat: vive en la variable de entorno `CONTEXT7_API_KEY` del usuario.
  1. Revisa si ya está a nivel usuario: `claude mcp list` (o
     `claude mcp get context7`). Si ya aparece con alcance `user`, no la
     dupliques en el proyecto: solo menciónala en `CLAUDE.md`.
  2. Si no está, propón configurarla **una vez para todos sus proyectos**
     y dale el comando para que lo corra él (así la key no pasa por ti):
     ```
     claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@<versión>
     ```
     En Windows nativo (no WSL), los servidores locales con `npx` van con
     el envoltorio `cmd /c`: `... context7 -- cmd /c npx -y @upstash/context7-mcp@<versión>`.
     El servidor toma la key de `CONTEXT7_API_KEY` automáticamente.
  3. Para definir la variable sin que quede en el historial de la terminal:
     - Windows (PowerShell): `$s = Read-Host "API key de Context7" -AsSecureString; [Environment]::SetEnvironmentVariable("CONTEXT7_API_KEY", [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)), "User")`
     - macOS / Linux: agregar `export CONTEXT7_API_KEY=...` a `~/.zshrc` o `~/.bashrc` con un editor.
     Después hay que reiniciar Claude Code.
  4. Si además quiere Context7 en el `.mcp.json` del proyecto (para que
     otros del equipo lo tengan), escríbelo referenciando la variable, nunca
     el valor: `"env": {"CONTEXT7_API_KEY": "${CONTEXT7_API_KEY:-}"}`.
- Antes de escribir la configuración real de cada MCP, verifica la sintaxis
  actual (documentación del MCP, o `docs.claude.com`) en vez de asumirla de
  memoria — el formato de configuración cambia entre herramientas y
  versiones. Como punto de partida verificado en octubre de 2026:
  Context7 = `npx -y @upstash/context7-mcp@<versión>`, Playwright =
  `npx -y @playwright/mcp@<versión>`, en `.mcp.json` bajo `mcpServers`.
  Fija la versión (`npm view <paquete> version`) en vez de dejar `latest`.
- Para GitHub, sugiere primero el CLI `gh` (ya lo usan los comandos del
  flujo); un MCP de GitHub solo si el usuario lo pide.
- **La misma regla para todo MCP o API que necesite credenciales**
  (GitHub, bases de datos, Supabase, Slack, Figma, APIs de LLM...):
  - Cada credencial vive en una variable de entorno del usuario, con nombre
    claro (`GITHUB_TOKEN`, `DATABASE_URL`, `SUPABASE_ACCESS_TOKEN`...). En
    `.mcp.json` se referencia (`"${VAR}"` en `env`, `args` o `headers`),
    nunca se escribe el valor. La app del proyecto la lee igual, desde el
    entorno o un `.env` que ya está en `.gitignore` y bloqueado para el agente.
  - Pregunta para cada MCP si lo quiere **en todos sus proyectos** (alcance
    `user`, con `claude mcp add --scope user ...`, lo corre él) o **solo en
    este** (`.mcp.json` del proyecto). Lo que ya tenga a nivel usuario
    (`claude mcp list`) no se duplica.
  - Para cada credencial, deja en `.env.example` el nombre de la variable
    con un valor vacío y un comentario de dónde se obtiene, y en
    `CLAUDE.md` (sección MCPs) qué variables necesita cada MCP.
  - Con permisos mínimos: tokens de solo lectura cuando el MCP solo
    consulta; para bases de datos, un usuario de solo lectura o una base de
    desarrollo, nunca la de producción.
  - Al terminar, pídele que corra `claude mcp list` y confirma que cada
    servidor aparece conectado; si alguno falla, casi siempre es una
    variable sin definir o Claude Code sin reiniciar.
  El hook `hardcoded-secret-detector` bloquea si alguien escribe una key
  de Context7, Anthropic, OpenAI o GitHub en un archivo.

## Paso 5 — Subagentes

Explica en una línea los 4 roles base (Coordinador, Implementador, Tester,
Auditor de seguridad — ver `references/sdd-fundamentals.md` si necesitas
recordar sus responsabilidades exactas) y pregunta: *"¿Te sirven estos 4 o
quieres agregar/quitar alguno (ej. Auditor de performance, Documentador,
Diseñador de UI)?"*

- Para cualquier subagente adicional que pida, exige especificidad: **qué
  hace exactamente**, **qué permisos tiene** (solo lectura / lectura y
  escritura), **a qué archivos o carpetas puede tocar**. No aceptes "que
  revise el código" sin acotar — pide una responsabilidad concreta y
  acotada, igual que los 4 roles base.
- Menciona en la misma respuesta (sin abrir una pregunta aparte) que
  los 4 roles quedan **definidos** pero no corren en cada cambio: un
  cambio chico (un endpoint simple, un bug evidente) lo hace el agente
  principal solo, protegido por los hooks; desde el nivel mediano trabajan
  los 4 roles: `coordinador` → `implementador` → `tester` +
  `auditor-seguridad` en paralelo, y en crítico se suma un especialista si
  aplica (ver "Proporcionalidad"). Y que según el proyecto se instalan especialistas: paquete **dev** siempre (comandos
  del flujo y skills de método) y paquete **ia** si en el paso 1 salió
  que hay datos, ML o LLMs. Si no quedó claro en el paso 1, pregúntalo
  aquí con una sola línea.
- Por defecto el nivel es **ligero**. Ofrece el nivel **completo**
  (38 especialistas, 54 skills) solo como opción, explicando que cuesta
  contexto en cada sesión.

## Paso 6 — Checklist de seguridad transversal

Avísale que vas a crear un checklist estándar de 11 puntos (validación de
inputs, control de acceso, manejo de secrets, protección contra
inyecciones, límites de rate, logging seguro, etc. — ver referencia) y
solo pregunta: *"¿Tu proyecto maneja datos de múltiples clientes/tenants
que deban estar aislados entre sí?"* (afecta un punto específico del
checklist). No conviertas esto en una entrevista larga — es mayormente
estándar.

- Si el proyecto usa LLMs o modelos de ML (paso 1), activa los puntos
  12-14 del template (salidas del modelo, prompt injection, datos y
  artefactos) sin preguntar más; si no, márcalos "No aplica".
- Explica en una línea que, además del checklist, el arnés **bloquea
  automáticamente** lo más peligroso (borrados, push a main, secretos,
  credenciales), sin depender de que el agente lo recuerde.

## Paso 7 — Features con las que arrancar

Pregunta: *"De tu roadmap, ¿con cuántas features quieres que te arme ya el
spec completo (spec.md + plan.md + tasks.md) para poder implementarlas de
una vez? Te recomiendo empezar con 1 a 3."*

- Para cada feature seleccionada, aclara rápido: **qué módulos toca**
  (backend/frontend/ambos), **de qué depende**, **qué queda fuera de
  alcance**. Sé ágil aquí — no vuelvas a discutir el roadmap completo, solo
  aterriza estos 3 datos por feature.
- Asigna tú el **nivel de riesgo** de cada feature (Chico / Mediano /
  Crítico) con la regla de `references/sdd-fundamentals.md` y muéstralo en
  el resumen del paso 8; no lo conviertas en pregunta.

## Paso 8 — Recapitulación final antes de tocar disco

Muestra un resumen compacto de todo lo capturado: misión en una frase,
stack, roadmap ordenado, MCPs a configurar, subagentes definidos, features
a generar con spec completo (con su nivel de riesgo), y la configuración
del arnés con sus defaults:

- Paquetes: base + dev [+ ia] · Nivel: ligero · CI en GitHub: sí ·
  Ciclo `@claude` en GitHub (revisión y auto-arreglo de PRs, gasta tokens
  de API): no.
- Flujo git: una rama por feature (`feat/NNN-nombre`), un commit por
  avance lógico, merge a `main` solo con OK explícito. Modo: **con remoto**
  (PR en GitHub) si el repo tiene `origin` en GitHub, si no **local**
  (`git merge --no-ff`). Detéctalo con `git remote -v` y confírmalo aquí.
  En la sección «Una rama por feature» del `CLAUDE.md` deja solo el modo
  elegido.

Pregunta explícitamente si procede con la generación de archivos antes de
crear nada, y si quiere cambiar algún default del arnés.

En este mismo paso, pregunta una sola vez: *"¿Hay alguna regla de 'no
hagas' específica que quieras además de las estándar (no borrar sin
avisar, no subir secrets, no instalar dependencias sin avisar)? Por
ejemplo, carpetas legacy que no debo tocar."*

## Generar los archivos

Con la confirmación del paso 8, crea esta estructura. Usa las plantillas
de `assets/` como base para cada archivo — rellénalas por completo con lo
que salió de la entrevista. Nunca dejes placeholders entre corchetes sin
resolver; usa `<!-- REVISAR -->` únicamente para lo genuinamente pendiente.

```
spec/
├── constitution/
│   ├── mission.md
│   ├── tech-stack.md
│   └── roadmap.md
└── features/
    ├── 000-seguridad-transversal/
    │   └── spec.md
    ├── 001-[feature]/
    │   ├── spec.md
    │   ├── plan.md
    │   └── tasks.md
    └── 00N-[feature]/...
CLAUDE.md
docs/
└── README.md   (regla de auto-actualización + formato de notas de sesión)
.claude/
├── agents/     (4 roles base + especialistas del nivel elegido)
├── hooks/      (instalados por el script del arnés)
├── rules/      (instaladas por el script del arnés)
├── commands/   (instalados por el script del arnés)
├── skills/     (instaladas por el script del arnés)
└── settings.json
.mcp.json       (solo si se confirmaron MCPs)
```

Además:

1. **CLAUDE.md** — usa `assets/CLAUDE.md.template`, rellenado por
   completo: stack real, comandos reales (si el proyecto ya existe;
   propuestos y marcados si es nuevo), estructura, convenciones, la
   sección "No hagas" (estándar + lo que el usuario haya pedido en el
   paso 8), y el flujo de trabajo con la regla de Build vs Plan Mode ya
   redactada explícitamente (ver `references/sdd-fundamentals.md` si
   necesitas el texto exacto recomendado). **Incluye también, sin
   excepción, la regla de auto-actualización de `docs/`** que ya trae el
   template — no la resumas ni la quites: es lo que hace que la memoria de
   sesión se mantenga sola en el tiempo, no solo al crearse. Conserva
   también "Proporcionalidad" y "Terminado significa", y en "Comandos del
   flujo" y "Reglas por tema" deja solo lo que realmente se instaló.
2. **MCPs** — escribe la configuración real de cada MCP confirmado en el
   paso 4, verificando la sintaxis vigente en vez de asumirla. Las
   credenciales siempre como `${VARIABLE}`, más su entrada vacía en
   `.env.example`; los MCPs que el usuario quiso en todos sus proyectos se
   entregan como comandos `claude mcp add --scope user ...` para que los
   corra él.
3. **Subagentes** — escribe la definición de cada subagente confirmado en
   el paso 5, usando el mecanismo de configuración de subagentes vigente
   en Claude Code (verifica la sintaxis actual en vez de asumirla). Para
   los 4 roles base parte de `assets/agentes/` (`coordinador.md`,
   `implementador.md`, `tester.md`, `auditor-seguridad.md`) y ajústalos al
   stack y a las carpetas reales del proyecto. Los adicionales que pidió
   el usuario, con el mismo formato, herramientas mínimas y `model:
   sonnet` salvo que pida otro.
4. **spec/features/000-seguridad-transversal/spec.md** — usa
   `assets/security-checklist.md.template`, ajustando el punto de
   aislamiento multi-tenant según la respuesta del paso 6 y los puntos
   12-14 según si hay LLMs o ML.
5. **Cada feature seleccionada en el paso 7** — usa
   `assets/spec.md.template`, `assets/plan.md.template` y
   `assets/tasks.md.template`, incluyendo en `tasks.md` los checks de
   seguridad transversal como indica el propio template, el nivel de
   riesgo en `spec.md` y la tabla criterio → test en `plan.md`.
6. **docs/README.md** — usa `assets/docs-README.md.template` tal cual;
   este archivo es lo que le recuerda al agente, en cualquier sesión
   futura, que `docs/` se actualiza solo sin que el usuario lo pida.
7. **Arnés** — corre el instalador incluido en esta skill (ruta relativa a
   la carpeta de la skill), con lo acordado en el paso 8:

   ```bash
   bash <carpeta-de-esta-skill>/scripts/instalar-arnes.sh \
     --destino <raíz del proyecto> \
     --stack python|node|ambos \
     --paquetes dev            # o dev,ia
     --nivel ligero            # o completo
     --llm no                  # si: el proyecto llama a LLMs (RAG, chat, agentes, evals)
     --api fastapi --app miapp.main:app   # solo si hay API FastAPI
     --ci si --claude-github no
   ```

   Instala hooks, `settings.json` (permisos y conexión de hooks), reglas,
   comandos, skills y especialistas, pre-commit, Ruff (Python) y el
   workflow de CI; agrega entradas a `.gitignore` y **prueba cada guard**
   antes de terminar. No crea `CLAUDE.md` ni `spec/` (eso lo haces tú) y
   nunca pisa archivos existentes. Si `jq` no está instalado, pide al
   usuario que lo instale (los hooks lo necesitan) y no sigas sin él.
   Con `--api fastapi`, ajusta después en `tests/arnes_config.py` las
   credenciales de prueba y las rutas públicas acordadas, agrega a la app
   las respuestas de error comunes (400/401/403) cuando exista, y avisa
   antes de correr `uv add --dev pytest pytest-cov schemathesis httpx`.
   Si no puedes ejecutar comandos en el entorno del usuario, entrégale el
   comando exacto para que lo corra.

## docs/ no es un paso único — es una regla permanente

A diferencia de la constitución (que se escribe una vez), `docs/` **se
actualiza en cada sesión de trabajo relevante durante toda la vida del
proyecto**, automáticamente, porque así quedó escrito en `CLAUDE.md`. Esta
skill solo se encarga de dejar la regla y la carpeta listas — a partir de
ahí, es el propio agente (guiado por su CLAUDE.md) quien mantiene `docs/`
al día en cada sesión futura, sin que esta skill vuelva a intervenir.

Si en algún momento notas que `docs/` no se está actualizando solo (el
agente no la revisó al empezar una tarea, o no dejó nota al cerrar una),
es una señal de que `CLAUDE.md` se está ignorando — recuérdaselo al
usuario en vez de simplemente seguir sin documentar.

## Después de generar

- Imprime el árbol de archivos final que quedó creado y el resumen del
  instalador del arnés (guards probados, cuántos subagentes, skills y
  comandos quedaron).
- Corre `python3 scripts/trazabilidad.py --escribir` para dejar
  `docs/trazabilidad.md` inicial (las features recién especificadas salen
  como "pendiente", sin fallar).
- Recuerda al usuario el siguiente paso inmediato: revisar que cada spec
  recién creada diga "LISTO PARA IMPLEMENTAR" antes de empezar a
  implementar (ver `references/sdd-fundamentals.md`, sección de revisión
  de spec).
- Dile cómo seguir: `/implementar spec/features/001-...` para construir,
  `/nueva-feature` para las siguientes del roadmap.
- Pendientes manuales, en una lista corta: proteger `main` en GitHub (PR
  obligatorio y CI requerido); el primer commit del andamiaje se hace en
  una rama o con `SKIP=no-commit-to-branch git commit ...`, porque
  pre-commit bloquea commits directos a `main` (el hook `git-flow-guard`
  te pedirá confirmarlo una vez); y, si activó el ciclo en
  GitHub, el secreto `ANTHROPIC_API_KEY` o `/install-github-app`.
- **No empieces a implementar código de ninguna feature todavía** — el
  trabajo de esta skill termina en el andamiaje, no en la construcción.

## Referencia

`references/sdd-fundamentals.md` contiene el ciclo SDD completo, los
niveles de adopción, el detalle de los 4 subagentes base, el checklist de
seguridad de 11 puntos, los prompts de verificación de spec, la regla de
proporcionalidad (cuánto verificar según el riesgo) y qué instala el
arnés. Consúltalo cuando necesites explicarle algo al usuario durante la
entrevista o cuando un archivo generado necesite más contenido del que
cabe en la plantilla.

`assets/arnes/` contiene los archivos que copia el instalador (módulos
base, dev e ia) y `assets/arnes/licencias/` las licencias de terceros:
hooks de cc-safe-setup (MIT), subagentes y skills de everything-claude-code
(MIT), wshobson/agents (MIT) y obra/superpowers (MIT), skills de
anthropics/skills (Apache-2.0) y workflows basados en las acciones
oficiales de Anthropic (MIT). No necesitas leerlos durante la entrevista.
