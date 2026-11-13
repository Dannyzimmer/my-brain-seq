# Instrucciones para agentes

Este repositorio define la convención canónica de los pipelines basados en Compi.
Antes de modificar un pipeline, lee en este orden:

1. `AGENTS.md` (este archivo).
2. `docs/pipeline-convention.md` (norma).
3. `docs/migrating-pipelines.md` (procedimiento de migración).
4. Solo los archivos del pipeline que vayas a modificar.

## Reglas obligatorias

- La plantilla es la fuente de verdad. `CalistoSearcher` es una implementación de
  referencia, no una fuente de reglas adicionales.
- El entrypoint debe llamarse como el software diseñado (`CalistoSearcher`,
  `GanymedeAnnotator`, etc.). En la plantilla se usa `PipelineCLI` como
  placeholder y debe renombrarse al instanciar un pipeline.
- Las variables estáticas van al XML del pipeline; las dinámicas, a EnvHandler.
- No introduzcas rutas absolutas de tu máquina ni credenciales.
- No cambies la lógica científica mientras migras el andamiaje. Son commits y
  fases distintas.
- No borres ni renombres salidas, parámetros o tareas sin justificarlo y sin
  actualizar XML, `environment.json`, metadatos, mensajes y documentación.
- No edites los binarios vendored (`EnvHandler`, `Logger`, `SIFManager`, `compi`)
  ni las dependencias de `resources/vendors/` salvo que la tarea lo pida.
- No ejecutes análisis completos, `wd-initialization` ni trabajos Slurm sobre
  datos reales sin confirmación explícita.
- No mezcles `test_config.json` (configuración de PipeTester) con
  `tests-config.json` (configuración raíz de Slurm).
- Si el comportamiento de un script no está claro, no lo inventes: deja un TODO
  explícito y pregunta.

## Flujo de trabajo

1. **Audita sin editar.** Produce una tabla con archivo, estado actual, objetivo,
   riesgo y acción. Usa referencias `archivo:línea`.
2. **Congela una línea base.** Ejecuta el test más pequeño posible y guarda
   parámetros, logs y hashes de las salidas.
3. **Migra por fases:** andamiaje, XML, entorno, scripts, mensajes/tests,
   metadatos y documentación.
4. **Valida cada fase** antes de continuar. No acumules cambios sin verificar.
5. **Compara con la línea base.** Si cambia una salida, explica por qué.
6. **Entrega un informe** con:
   - archivos modificados;
   - decisiones tomadas;
   - validaciones ejecutadas;
   - diferencias conocidas y TODOs;
   - riesgos pendientes.

## Criterios de finalización

- El pipeline conserva su comportamiento científico.
- El entrypoint expone `run`, `test` y `templates cparams`.
- `main.xml` tiene el prelude canónico y un DAG sin ciclos.
- `environment.json` resuelve todas las rutas y claves necesarias.
- `wd-initialization` recrea únicamente directorios de salida declarados.
- Los mensajes usados existen en `msg_main.json` o `msg_tests.json`.
- Los metadatos de parámetros y salidas son coherentes con el XML.
- `test_config.json` de PipeTester y, si aplica, `tests-config.json` de Slurm
  siguen siendo válidos.
- `git diff --check` pasa y no se han añadido secretos ni artefactos generados.
- Se han hecho commits atómicos por fase y push al terminar, salvo instrucción
  contraria del usuario.
