# Migración de pipelines a la convención

Este documento define el procedimiento para adaptar un pipeline antiguo a la
convención descrita en `docs/pipeline-convention.md`.

La migración MUST conservar el comportamiento científico. El objetivo es
cambiar el andamiaje, no reescribir el análisis.

## 0. Preparación

Antes de tocar código:

- Lee `docs/pipeline-convention.md`.
- Identifica el entrypoint actual y anota su ruta exacta.
- Localiza el `main.xml`, el runner, el entorno y los scripts científicos.
- Comprueba si existen `test_config.json`, `tests-config.json`,
  `parameters.metadata.json` y `outputs.metadata.json`.
- No ejecutes análisis completos ni trabajos Slurm sin confirmación.

Crea una tabla de auditoría:

| Archivo o componente | Estado actual | Objetivo | Riesgo | Acción |
|---|---|---|---|---|
| Entrypoint | `./old-cli` | `<SoftwareName>` | Cambia llamadas externas | Renombrar y actualizar configs |
| `main.xml` | Sin prelude | Prelude canónico | DAG incorrecto | Reordenar tareas |
| Entorno | Claves ad hoc | `environment.json` | Rutas rotas | Normalizar claves |
| Tests | Inexistentes | `test_config.json` | Sin cobertura | Añadir fixture mínimo |

Cada fila SHOULD incluir evidencias `archivo:línea`.

## 1. Congelar la línea base

1. Elige el test más pequeño que ejercite el pipeline.
2. Guarda una copia de `compi.parameters`.
3. Ejecuta el pipeline y guarda logs y salidas.
4. Calcula hashes de las salidas relevantes.
5. Guarda la versión de Compi, contenedores y entorno.

Si no se puede ejecutar el pipeline completo, guarda al menos:

- `test` o `--until checks` con `runChecks`;
- la estructura del árbol de salidas;
- los metadatos y nombres de ficheros esperados.

No empieces la migración sin una línea base o una justificación explícita.

## 2. Copiar el andamiaje canónico

Copia desde la plantilla, sin arrastrar lógica científica:

- entrypoint;
- `resources/runners/main.sh`;
- `resources/env/config/environment.json`;
- `resources/env/shared/{environment,printer,tests}.sh`;
- `resources/env/tools/`;
- `resources/pipelines/main.xml` como esqueleto;
- `resources/scripts/{env-preparation,container-preparation,wd-initialization}.sh`;
- `resources/data/messages/`;
- `resources/data/metadata/` como esqueletos;
- `params-examples/compi.parameters`;
- `README.md` como plantilla documental.

Después:

- renombra el entrypoint al nombre del software;
- sustituye `[PIPELINE_NAME]` por el nombre real;
- no copies `[CALISTO]` ni tareas científicas de Calisto.

Commit sugerido: `Add canonical pipeline scaffolding`.

## 3. Normalizar `main.xml`

1. Conserva el orden de parámetros por categorías.
2. Declara todos los parámetros que usan los scripts.
3. Marca requeridos sin default y opcionales con default.
4. Convierte flags a `<flag>`.
5. Renombra parámetros a `camelCase` y `shortName` únicos.
6. Añade el prelude:

```text
parameter-validation
checks
env-preparation
container-preparation
wd-initialization
```

7. Conecta las tareas científicas existentes después del prelude.
8. Verifica que no hay ciclos ni IDs duplicados.
9. Añade comentarios de interfaz a cada tarea.
10. Sustituye rutas hardcodeadas por `${pipelineDir}`, `${workingDir}` o
    variables de EnvHandler.

No cambies el orden científico de las tareas sin autorización.

Commit sugerido: `Normalize pipeline XML and task graph`.

## 4. Normalizar `environment.json`

1. Define las claves base: `wd`, `pipeline`, `scripts`, `bin`, `data`,
   `messages`, `output`.
2. Añade cada directorio de salida como `output::<slug>` con padre `output`.
3. Añade los scripts como `add-file` bajo `scripts`.
4. Añade binarios vendored como `bin:<nombre>`.
5. Mueve a EnvHandler solo lo dinámico; lo estático debe seguir en el XML.
6. Elimina rutas absolutas y referencias a directorios locales.
7. Comprueba que `wd-initialization` puede resolver y recrear todas las salidas.

Commit sugerido: `Normalize runtime environment paths`.

## 5. Adaptar scripts científicos

Hazlo de uno en uno. Para cada script:

1. Añade `source "${environment}"`.
2. Añade `LOAD_PRINTER` si emite mensajes.
3. Sustituye rutas hardcodeadas por `ENV path get-dir/get-file`.
4. Sustituye valores dinámicos por `ENV param get`.
5. Sustituye mensajes por `msg namespace.KEY`.
6. Registra cada salida con `ENV path add-file`.
7. Mantén la lógica científica intacta.
8. Añade `set -o nounset` y `set -o errexit` si faltan.
9. Ejecuta `bash -n` antes de continuar.

No refactorices algoritmos, nombres de columnas o formatos de salida en esta
fase. Si detectas un bug científico, anótalo y trátalo en un cambio separado.

Commit sugerido por grupo de scripts: `Adapt <group> scripts to EnvHandler`.

## 6. Mensajes, checks y tests

1. Añade a `msg_main.json` todas las claves usadas por `msg`.
2. Añade a `msg_tests.json` las claves usadas por `test_msg`.
3. Implementa o adapta `checks.sh` para validar entorno y entradas.
4. Adapta `checks-parameters.sh` y `parameters.metadata.json`.
5. Añade grupos, widgets y validaciones a los parámetros públicos.
6. Crea `test_config.json` para PipeTester con el fixture mínimo.
7. Si usas Slurm, mantén `tests-config.json` en la raíz de tests y
   `run_test.sh` en cada test.
8. Comprueba que todas las claves de mensaje existen.

Commit sugerido: `Add pipeline checks and test configuration`.

## 7. Metadatos de salida

Si el pipeline va a usarse con PipeTester:

1. Crea grupos de salida estables.
2. Añade cada salida con `id`, `label`, `path`, `kind`, `base`, `match`, `role`,
   `required`, `multiple`, `order` y `group`.
3. Usa `${PARAM:<nombre>}` para rutas dependientes de parámetros.
4. Usa `base: outDir` o `base: workingDir` correctamente.
5. Añade `viewer` cuando el tipo de fichero lo requiera.
6. Verifica que todas las rutas apuntan a salidas realmente producidas.

Commit sugerido: `Document pipeline outputs metadata`.

## 8. Validación

Ejecuta, como mínimo:

```bash
bash -n resources/runners/main.sh
bash -n resources/scripts/*.sh
bash -n resources/env/shared/*.sh
xmllint --noout resources/pipelines/main.xml
python3 -m json.tool resources/env/config/environment.json
python3 -m json.tool resources/data/messages/msg_main.json
python3 -m json.tool resources/data/messages/msg_tests.json
python3 -m json.tool resources/data/metadata/parameters.metadata.json
python3 -m json.tool resources/data/metadata/outputs.metadata.json
git diff --check
```

Después:

1. Ejecuta el entrypoint con `test` y `runChecks`.
2. Ejecuta el test mínimo.
3. Compara salidas y hashes con la línea base.
4. Abre el test en PipeTester.
5. Si aplica, valida el envío Slurm en seco.
6. Revisa que no se hayan modificado binarios vendored ni secretos.

Si una salida cambia, no la aceptes sin explicar la causa.

## 9. Informe final

El agente MUST entregar:

```markdown
## Resultado

- Entrypoint:
- Nivel de conformidad: core / standard / full
- Archivos modificados:
- Archivos eliminados:
- Decisiones de nombres:
- Validaciones ejecutadas:
- Salidas comparadas:
- Diferencias conocidas:
- TODOs:
- Riesgos:
```

Incluye los comandos exactos y su resultado. No afirmes que algo funciona si no
se ha ejecutado.

## 10. Casos especiales

### El entrypoint antiguo tiene otro nombre

Renómbralo al nombre del software o crea un wrapper compatible. Actualiza
`tests-config.json`, tareas de VS Code y documentación.

### El pipeline usa `initialization.sh`

Migra a `wd-initialization.sh` y actualiza el `task id`. No mantengas dos
nombres salvo que sea necesario para compatibilidad externa.

### El pipeline usa `output:`

Normaliza a `output::<slug>`. `wd-initialization` busca el prefijo `output:%`,
pero la convención usa `output::`.

### El pipeline usa `test-config.json`

Corrige a `test_config.json` si es configuración de PipeTester. Mantén
`tests-config.json` solo para la raíz de tests de Slurm.

### No hay metadatos

Empieza con los esqueletos vacíos. Añade metadatos solo para parámetros y salidas
que realmente existan.

### Hay rutas absolutas

Sustitúyelas por claves de entorno. Si una ruta es realmente externa, conviértela
en parámetro público documentado.

## 11. Reglas de parada

El agente MUST preguntar antes de:

- cambiar nombres de parámetros públicos;
- alterar el orden científico de tareas;
- borrar salidas o scripts;
- ejecutar análisis costosos o trabajos Slurm;
- modificar binarios vendored;
- cambiar contratos de columnas o formatos de salida.

El agente MUST dejar un TODO explícito si no puede determinar el comportamiento
esperado.

## 12. Prompt reutilizable

```text
Vas a migrar un pipeline Compi a la convención canónica.

Lee, en este orden:
1. AGENTS.md
2. docs/pipeline-convention.md
3. docs/migrating-pipelines.md
4. Solo los archivos del pipeline que necesites.

No cambies la lógica científica. No inventes parámetros ni salidas. No ejecutes
análisis completos sin permiso.

Primero entrega una tabla de auditoría con evidencias archivo:línea y un plan por
fases. Después implementa una fase, valídala y haz un commit atómico. Al final,
compara con la línea base y entrega el informe final definido en la guía.

Si encuentras una ambigüedad que afecte al comportamiento, pregunta.
```
