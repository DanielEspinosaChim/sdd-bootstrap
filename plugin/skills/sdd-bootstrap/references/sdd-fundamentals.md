# Fundamentos de SDD — referencia de apoyo

Este archivo es material de consulta para usar durante la entrevista de
`sdd-bootstrap` o al redactar los archivos generados. No es necesario
leerlo entero de una vez; ve a la sección que necesites.

## El ciclo SDD

1. **Constitución** (una vez por proyecto): mission.md, tech-stack.md, roadmap.md.
2. **Specify**: qué se va a construir, con criterios de aceptación verificables.
3. **Plan**: cómo se va a construir — archivos exactos, endpoints, modelo de datos.
4. **Tasks**: el plan dividido en tareas pequeñas y verificables.
5. **Implement**: se ejecutan las tareas una a una.
6. **Verify**: se valida contra los criterios de aceptación; si falla, se ajusta.

El ciclo Specify → Plan → Tasks → Implement → Verify se repite en cada
feature nueva.

## Niveles de adopción

- **Spec-first**: la spec es el punto de partida; se genera el código una
  vez y luego se edita directo. Rápido, pero la spec se desactualiza.
- **Spec-anchored** (recomendado por default): la spec se mantiene viva —
  cada cambio importante pasa primero por actualizarla. Es el nivel que
  esta skill asume al generar el scaffold.
- **Spec-as-source**: la spec es lo único que se edita; el código se
  regenera siempre desde ella. Experimental, poco común todavía.

## Los 4 subagentes base

- **Coordinador**: no escribe código. Lee la tarea, la divide en
  subtareas y decide el orden y a qué subagente asignar cada una.
- **Implementador**: recibe una subtarea concreta y escribe el código.
  Puede haber varios en paralelo.
- **Tester**: corre y escribe tests (unit, integración, E2E). Valida que
  el resultado cumpla los criterios de aceptación de la spec
  correspondiente. No modifica código de producción, solo tests.
- **Auditor de seguridad**: acceso de solo lectura. Revisa inyecciones,
  manejo de secrets, validación de inputs, control de acceso y
  dependencias con CVEs conocidos.

Cada subagente devuelve solo un resumen de su trabajo al Coordinador —
nunca todo el detalle — para no saturar el contexto principal.

Subagentes adicionales comunes que el usuario puede pedir:
- **Auditor de performance**: cuellos de botella, queries lentas, uso de
  memoria. Solo lectura.
- **Documentador**: mantiene README y docs/ actualizados tras cada
  feature. Solo puede escribir en carpetas de documentación, no en código.

## Checklist de seguridad transversal (11 puntos)

Usar como base para `spec/features/000-seguridad-transversal/spec.md`:

1. Validación de todos los inputs de usuario (tipo, formato, longitud).
2. Control de acceso verificado en cada endpoint (autenticación +
   autorización, no solo autenticación).
3. Aislamiento multi-tenant: un usuario/cliente nunca puede leer o
   modificar datos de otro (si el proyecto maneja múltiples tenants).
4. Manejo de secrets: nada de credenciales, tokens o llaves hardcodeadas
   ni en el repo.
5. Protección contra inyecciones (SQL, NoSQL, comandos de sistema).
6. Protección contra XSS/CSRF en cualquier superficie web.
7. Límites de rate en endpoints públicos o sensibles.
8. Logging seguro: no se registran contraseñas, tokens ni datos
   personales sensibles en texto plano.
9. Manejo de errores que no filtra información interna (stack traces,
   rutas de archivo, versiones de librerías) al cliente.
10. Dependencias sin vulnerabilidades conocidas (CVEs) sin mitigar.
11. Subida de archivos (si aplica) validada por tipo real, tamaño máximo,
    y almacenada fuera de rutas ejecutables.

Si el proyecto no maneja tenants, el punto 3 se marca como "No aplica" en
el spec generado en vez de eliminarse — para que quede explícito que se
consideró.

## Revisión de spec antes de implementar

Antes de dar luz verde a implementar cualquier feature, se revisa que:

1. `spec.md` tenga al menos 5 criterios de aceptación verificables (no ambiguos).
2. `plan.md` liste archivos exactos a crear/modificar (no genéricos).
3. `plan.md` tenga los endpoints con método, path y descripción.
4. `plan.md` tenga el modelo de datos con campos y tipos.
5. `tasks.md` esté dividido en secciones con tareas atómicas.
6. `tasks.md` incluya al menos un test de aislamiento (multi-tenant si aplica).
7. No queden `<!-- REVISAR -->` sin resolver.
8. `spec.md` declare su nivel de riesgo (Chico / Mediano / Crítico).
9. `plan.md` tenga la tabla "Verificación por criterio": cada criterio de
   aceptación apunta a un test concreto.

Si todo se cumple: **LISTO PARA IMPLEMENTAR**. Si no: se listan los puntos
faltantes y no se avanza a implementación.

## Texto recomendado para la sección "Flujo de trabajo" de CLAUDE.md

```
## Flujo de trabajo
- Para tareas grandes, refactors, o cambios que toquen más de 2 archivos:
  usa Plan Mode. Muestra el plan completo y espera mi OK explícito antes
  de tocar código.
- Para bugs evidentes, correcciones puntuales o tareas atómicas de un
  solo archivo: usa Build Mode y ejecuta directo.
- Una tarea a la vez; al terminar, dime qué cambiaste para que lo revise.
- Si no estás seguro al 80%, pregunta. No inventes.
```

## Loop engineering (para el bucle de verificación por feature)

Antes de cerrar una feature, se corre el bucle *Actuar → Observar →
Corregir* hasta que todos los tests pasen: el agente ejecuta, corre las
pruebas, si algo falla identifica la causa y corrige, y repite — sin
necesidad de que el humano supervise cada vuelta individual, solo el
resultado final.

## Proporcionalidad: cuánto verificar según el riesgo

El objetivo es seguridad y calidad sin gastar tokens ni tiempo de más. Los
hooks del arnés (bloqueos, lint al editar, tests al terminar) cuestan casi
cero tokens porque son scripts; los subagentes cuestan contexto y tiempo,
así que se usan solo donde pagan:

| Nivel | Ejemplos | Verificación |
|---|---|---|
| Chico | Endpoint CRUD simple, bug evidente, un archivo | Test + lint + tipos, revisión propia. Sin subagentes: el agente principal cubre los 4 roles. |
| Mediano | Feature de varios archivos, lógica de negocio nueva | Los 4 roles: coordinador → implementador → tester + auditor-seguridad en paralelo. |
| Crítico | Auth, permisos, pagos, PII, multi-tenant, migraciones, ML/LLM a producción | Los 4 roles, auditoría del checklist completo, + un especialista si aplica. |

Cada `spec.md` declara su nivel; `/implementar`, `/revisar` y `/verificar`
lo leen para decidir el esfuerzo. Ante la duda, el nivel mayor, dicho en el resumen. Un endpoint
simple que toca auth, permisos, pagos o datos personales es crítico.

## El arnés que instala la skill (capas)

- **Dura (la máquina lo hace cumplir):** hooks en `.claude/hooks/` y lista
  `deny` en `.claude/settings.json`. Bloquean `rm -rf`, push a main, push
  forzado, `reset --hard`, `sudo`, `curl | bash`, lectura de `.env` y
  credenciales, búsqueda de secretos, borrado de bases de datos, `pip
  --break-system-packages`; detectan secretos escritos en código; corren
  Ruff al editar Python; no dejan terminar con tests rojos (tope 3
  intentos) ni decir "listo" sin haber verificado (estos dos últimos solo
  actúan cuando hay cambios de código).
- **Verificación automática:** pre-commit (Gitleaks, Semgrep, Ruff, nada
  directo a main, notebooks limpios) y CI (tests, lint, tipos, auditoría
  de dependencias, Gitleaks, Semgrep, Trivy).
- **Suave (instrucciones):** `CLAUDE.md`, reglas en `.claude/rules/` que
  se cargan solo al tocar archivos que coinciden, comandos del flujo.
- **Opcional:** ciclo en GitHub (`@claude` en issues, revisión automática
  de PRs, auto-arreglo de CI). Gasta tokens de API en cada corrida; se
  activa solo si el usuario lo pide.

Los 4 roles base de SDD se escriben como subagentes reales en
`.claude/agents/` (`coordinador`, `implementador`, `tester`,
`auditor-seguridad`). En cambios chicos no corren (el agente principal
cubre los roles y los hooks protegen); desde el nivel mediano trabajan los
4. Varios `implementador` en paralelo solo para tareas `[P]` independientes
y largas. En el nivel completo se agrega `verifier`
(revisión adversarial opcional, solo si el usuario la pide). Los especialistas de los paquetes
(revisores por lenguaje, ML, RAG, arquitectura...) se agregan según el
nivel de instalación.

## Pruebas automáticas: calidad y seguridad en cada endpoint sin gastar tokens

Lo que se puede comprobar con una máquina no se le deja a un agente:

| Prueba | Qué atrapa | Dónde corre |
|---|---|---|
| Unitarias + cobertura del diff ≥ 90 % (diff-cover) | Código nuevo sin test | Local y CI |
| Trazabilidad `C<NNN>-<n>` (`scripts/trazabilidad.py`) | Criterios de aceptación sin test | pre-commit y CI |
| Contrato por endpoint (Schemathesis) | 500s, respuestas fuera del esquema, códigos no documentados, auth ignorada, validaciones flojas | pytest (local y CI) |
| Seguridad por endpoint (`test_seguridad_endpoints.py`) | Rutas sin auth, credenciales falsas aceptadas, trazas o errores de BD filtrados | pytest (local y CI) |
| OpenAPI exportado (`docs/api/openapi.json`) | Documentación de la API desactualizada | pre-commit y CI |
| Ruff (reglas `S`), Semgrep, Gitleaks, Trivy, pip-audit | Código inseguro, secretos, CVEs | pre-commit y CI |

Las de contrato y seguridad recorren todos los endpoints de la app, así
que un endpoint nuevo queda cubierto sin escribir pruebas para él. En una
prueba con tres errores plantados (ruta sin auth, división entre cero,
traza filtrada) las tres los detectaron sin código de prueba específico.

Además, un hook pide confirmación humana si el agente debilita un test
para hacerlo pasar: quitar asserts o condiciones, marcar skip/xfail/only,
o cambiar un valor esperado en un test ya commiteado (los tests escritos
en la sesión actual se pueden ajustar libremente mientras se trabaja).

Límite honesto: no detectan errores de lógica de negocio (un cálculo
correcto en forma pero equivocado en valor) ni fugas entre tenants: esos
los cubren los tests por criterio y, desde el nivel mediano, el `tester` y
el `auditor-seguridad`.

## Nivel de instalación: ligero o completo

- **Ligero (defecto):** lo esencial para el stack. Alrededor de 700 a
  1,100 tokens de descripciones por sesión.
- **Completo:** todos los especialistas y skills de los paquetes elegidos
  (38 subagentes además de los 4 roles base, 54 skills). Alrededor de 7,000 tokens por sesión. Útil
  en proyectos grandes o equipos; se pide explícitamente.

Siempre se puede pasar de ligero a completo después corriendo el
instalador otra vez con `--nivel completo`: no pisa nada.
