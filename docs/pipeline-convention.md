# Convención de pipelines Compi

- **Versión:** 1.0.0
- **Estado:** normativa
- **Implementación de referencia:** `CalistoSearcher`
- **Plantilla canónica:** este repositorio (`pipeline_template`)

Esta convención describe el andamiaje común de los pipelines basados en Compi.
No describe la lógica científica de cada pipeline: esa lógica vive en las tareas
de análisis y debe conservarse durante una migración.

Las palabras **MUST**, **SHOULD** y **MAY** expresan obligación, recomendación y
opción respectivamente.

## 1. Niveles de conformidad

### Core

Todo pipeline MUST cumplir:

- entrypoint ejecutable con `run`, `test` y `templates cparams`;
- runner común;
- `resources/pipelines/main.xml` con el prelude canónico;
- `resources/env/config/environment.json`;
- scripts `env-preparation.sh`, `container-preparation.sh` y
  `wd-initialization.sh`;
- `resources/env/shared/environment.sh` y `resources/env/shared/printer.sh`;
- `params-examples/compi.parameters`;
- `README.md` con descripción, uso y parámetros.

### Standard

Además de Core, SHOULD incluir:

- `checks.sh`, `checks-parameters.sh` y `compipar_bridge.py`;
- `msg_main.json` y `msg_tests.json`;
- `resources/vendors/containers/containers.json` si usa contenedores;
- `parameters.metadata.json` coherente con el XML;
- configuración de test de PipeTester (`test_config.json`).

### Full

Además de Standard, MAY incluir:

- `outputs.metadata.json` poblado;
- recursos Slurm (`other-resources/slurm/`);
- tests de aceptación con datos y salidas esperadas;
- documentación específica de resultados y visores.

## 2. Árbol canónico

```text
<PipelineName>/
├── <SoftwareName>                  # Entrypoint ejecutable (plantilla: PipelineCLI)
├── README.md
├── params-examples/
│   └── compi.parameters
├── resources/
│   ├── compi-1.5.2/
│   │   └── compi
│   ├── data/
│   │   ├── messages/
│   │   │   ├── msg_main.json
│   │   │   └── msg_tests.json
│   │   └── metadata/
│   │       ├── parameters.metadata.json
│   │       └── outputs.metadata.json
│   ├── env/
│   │   ├── config/environment.json
│   │   ├── shared/
│   │   │   ├── environment.sh
│   │   │   ├── printer.sh
│   │   │   └── tests.sh
│   │   └── tools/
│   │       ├── EnvHandler
│   │       ├── Logger
│   │       └── SIFManager
│   ├── pipelines/main.xml
│   ├── runners/main.sh
│   ├── scripts/
│   └── vendors/
│       ├── bin/
│       ├── click/
│       ├── compipar_validator/
│       ├── containers/containers.json
│       └── scripts/
└── other-resources/                # Opcional / Full
    └── slurm/
        ├── README.md
        ├── run_test.sh
        └── tests-config.json
```

El directorio `resources/scripts/` es la **zona de extensión**: contiene las
tareas científicas del pipeline. El resto del árbol es andamiaje común.

## 3. Entrypoint y runner

### Entrypoint

- MUST llamarse como el software diseñado. Ejemplo: `CalistoSearcher`.
- En la plantilla se usa `PipelineCLI` como placeholder; al instanciar el
  pipeline MUST renombrarse.
- MUST exponer:
  - `run <compi.parameters> [--add-params ...]`;
  - `test <compi.parameters>`;
  - `templates cparams <output_path>`.
- `run` delega en `resources/runners/main.sh`.
- `test` ejecuta el prelude hasta `checks` con `--runChecks`.
- `templates cparams` copia `params-examples/compi.parameters`.

### Runner

`resources/runners/main.sh` MUST:

- aceptar `<params-file> <pipeline-path> <pipeline-root> [args...]`;
- separar opciones generales de Compi y parámetros del pipeline con `--`;
- resolver `compiDir`, `shareDir` y `environment.sh` desde `main.xml`;
- añadir `--pipelineDir`, `--environment` y `--compiParameters`;
- crear `workingDir/logs/<timestamp>/`;
- ejecutar Compi con `-p`, `--logs`, `-pa`, `-o` y `--`;
- propagar el código de salida de Compi;
- si existe `.parameter_validation_failed`, borrarlo y salir con error.

## 4. Contrato de `main.xml`

### Parámetros

- Todos los parámetros que Compi pasa a las tareas MUST declararse en `<params>`.
- Las rutas estáticas MUST declararse en el XML, con `defaultValue` relativo a
  `pipelineDir` cuando corresponda.
- Las rutas y valores generados en ejecución MUST registrarse en EnvHandler.
- Los parámetros públicos MUST usar `camelCase`.
- `shortName` MUST ser único.
- Los parámetros requeridos por el usuario MUST no tener `defaultValue`.
- Los opcionales MUST usar un valor por defecto explícito. Los centinelas
  habituales son `FALSE` y `AUTO`.
- Los flags MUST declararse con `<flag>`, no como parámetros con valor.
- Los parámetros de script SHOULD terminar en `Scr`.
- Los parámetros de directorios de salida SHOULD terminar en `Out`.
- Mantén los comentarios de categoría: directorios privados, ficheros privados,
  scripts, requeridos, opcionales, flags y salidas.

### Tareas

El prelude MUST tener este orden lógico:

```text
parameter-validation -> checks -> env-preparation
                     -> container-preparation -> wd-initialization -> tareas de análisis
```

- `parameter-validation` MUST ejecutarse antes de `checks` y MUST estar
  condicionada por `runChecks`.
- `checks` MUST depender de `parameter-validation`.
- `env-preparation` MUST depender de `checks`.
- `container-preparation` MUST depender de `env-preparation`.
- `wd-initialization` MUST depender de `container-preparation`.
- Los `id` MUST ser únicos, en `kebab-case` y estables.
- Las dependencias MUST declararse con `after`; no puede haber ciclos.
- Los scripts MUST invocarse mediante `${pipelineDir}` y una ruta declarada.
- Cada tarea SHOULD incluir un comentario de interfaz:

```text
Input:
  reads.fastq          - raw sequencing reads (FASTQ)
Output:
  alignment.bam        - aligned reads (BAM)
Parameters:
  min_mapping_quality  - integer; default: 20
```

- La lógica científica compleja MUST vivir en `resources/scripts/`, no en el
  XML. El XML solo orquesta, condiciona y ejecuta contenedores.
- Los `if` y `foreach` MUST usar rutas resueltas y comillas correctas.

## 5. Contrato de `environment.json`

`resources/env/config/environment.json` es declarativo. Solo contiene entradas
`path` y `param`; no contiene lógica.

### Claves base

| Clave | Contenido |
|---|---|
| `wd` | `workingDir` |
| `pipeline` | `pipelineDir` |
| `scripts` | Directorio de scripts |
| `bin` | Binarios vendored |
| `data` | Datos auxiliares |
| `messages` | JSON de mensajes |
| `output` | Directorio raíz de salidas |

### Claves de salida

- Cada subdirectorio de salida MUST registrarse como `output::<slug>` con padre
  `output`.
- `wd-initialization` MUST crear y recrear todos los directorios que coincidan
  con `output:%`.
- Los directorios de salida MUST ser descartables. `wd-initialization` los borra.

### Otras claves

- Scripts: `add-file` con padre `scripts` y clave `<nombre>Scr`.
- Binarios: `bin:<nombre>`.
- Contenedores: `singularity::<nombre>`.
- Artefactos de dominio: `<namespace>:<nombre>`, registrados en ejecución.

### Reglas

- No incluyas rutas absolutas de tu máquina.
- No dupliques en el JSON una ruta que ya existe en el XML.
- Los valores MUST resolverse desde `${pipelineDir}` o `${workingDir}`.
- `env-preparation.sh` MUST hacer `ENV reset` y cargar el JSON antes de que
  cualquier tarea use EnvHandler.

## 6. Contrato de scripts

### Cabecera

```bash
#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER
```

- `set -o pipefail` SHOULD añadirse cuando haya tuberías.
- `LOAD_TESTS` solo en scripts de validación.
- `LOAD_SINGULARITY_ENV` solo cuando se usen contenedores.

### Acceso a datos

- Parámetros de Compi: variables directas (`${workingDir}`, `${threads}`).
- Valores dinámicos: `ENV param get <clave>`.
- Directorios: `ENV path get-dir <clave>`.
- Ficheros: `ENV path get-file <clave>`.
- Salidas: `ENV path add-file [--force] <clave> <ruta> <padre>`.

### Mensajes

- Los mensajes visibles MUST salir de `msg <namespace>.<KEY>`.
- No escribas mensajes de usuario hardcodeados en los scripts, salvo errores
  internos o ayuda de uso.
- Añade la clave a `msg_main.json` antes de usarla.

### Comportamiento

- Los scripts MUST fallar con código distinto de cero ante errores.
- Los scripts SHOULD ser idempotentes, excepto `wd-initialization`.
- No asumas el directorio actual: usa rutas absolutas construidas desde
  `${pipelineDir}` y `${workingDir}`.

## 7. Mensajes

`msg_main.json` y `msg_tests.json` son arrays de objetos con este contrato:

| Campo | Obligatorio | Descripción |
|---|---|---|
| `namespace` | sí | Agrupación lógica |
| `key` | sí | Clave única dentro del namespace |
| `severity` | sí | `info`, `warning`, `error` o `fatal` |
| `message` | sí | Texto con placeholders `{nombre}` |
| `indented` | no | `0` o `1` |
| `order` | no | Orden de presentación |

- Los placeholders se pasan como `nombre=valor` al llamar a `msg`.
- `msg_main.json` contiene mensajes del pipeline.
- `msg_tests.json` contiene mensajes de `checks.sh` y de las funciones de test.
- No reutilices una clave con otro texto.
- `test_msg` y `test_msg_custom` leen de `msg_tests.json`.
- `test_passed` y `test_failed` se usan para resultados directos sin JSON.

## 8. Checks y validación de parámetros

### `checks.sh`

- Valida entorno, entradas de usuario y recursos.
- Debe poder ejecutarse con `runChecks`.
- Los fallos obligatorios MUST producir un código de salida distinto de cero.
- Usa `test_*`, `msg`, `test_passed` y `test_failed` de forma consistente.
- Mantén `die` para poder recoger varios errores en modo test, pero asegura que
  el resultado final siga siendo fallido si algún check obligatorio falla.

### `checks-parameters.sh`

- Ejecuta `compipar_bridge.py` contra `parameters.metadata.json`.
- Los errores `strict` bloquean; los avisos no.
- Si hay error, crea `${workingDir}/.parameter_validation_failed`.
- El runner MUST convertir ese marcador en un fallo real.

### `parameters.metadata.json`

Esquema 1:

```json
{
  "schema_version": 1,
  "parameters": {},
  "validations": []
}
```

- `parameters` mapea cada parámetro a su widget, grupo y opciones.
- `validations` declara relaciones como `at_most_one` o `exactly_one`.
- Los parámetros del XML y del metadata MUST estar sincronizados.
- CalistoSearcher es el ejemplo completo de referencia.

## 9. Metadatos de salida

`outputs.metadata.json` describe las salidas para PipeTester y otros visores.

Esquema 1:

```json
{
  "schema_version": 1,
  "groups": [],
  "outputs": []
}
```

- `groups` define `id`, `label` y `order`.
- Cada output define `id`, `label`, `path`, `kind`, `base`, `match`, `role`,
  `required`, `multiple`, `order`, `group` y, opcionalmente, `viewer`.
- `path` admite el token `${PARAM:<nombre>}`.
- `base` es `outDir` o `workingDir`.
- `kind` es, por ejemplo, `image`, `table`, `fasta`, `tree` o `file`.
- Los `id` y `label` MUST ser estables.
- La plantilla parte de un esqueleto vacío; CalistoSearcher es el ejemplo real.

## 10. Configuración de tests y Slurm

### PipeTester

- Cada directorio de test usa `test_config.json`.
- Contiene la configuración de entrada, parámetros y salidas esperadas según el
  esquema de PipeTester.
- No lo confundas con `tests-config.json`.

### Slurm

- `other-resources/slurm/tests-config.json` vive en la raíz de los tests.
- Contiene `pipeline_entrypoint`.
- Cada test puede tener su `run_test.sh` con directivas `#SBATCH`.
- `run_test.sh` invoca el entrypoint con `run` y el `compi.parameters` del test.

## 11. Convenciones de nombres

| Elemento | Convención | Ejemplo |
|---|---|---|
| Parámetros | `camelCase` | `workingDir` |
| Flags | `camelCase` | `runChecks` |
| Tareas | `kebab-case` | `blast-nt` |
| Scripts | `kebab-case.sh` | `blast-nt.sh` |
| Directorios de salida | `N_slug` | `3_blast-nt` |
| Claves de salida | `output::<slug>` | `output::blastNtOut` |
| Mensajes | `namespace.KEY` | `checks.ENV_TEST` |
| Contenedores | `singularity::<nombre>` | `singularity::blast` |
| Binarios | `bin:<nombre>` | `bin:quicktree` |

## 12. Antipatrones

- Rutas absolutas de la máquina del autor.
- Mensajes de usuario hardcodeados en scripts.
- Lógica científica dentro de `main.xml`.
- Salidas escritas sin registrarse en EnvHandler.
- Directorios de salida no declarados en `environment.json`.
- Tareas sin `after` o con dependencias cíclicas.
- Scripts sin `source "${environment}"`.
- Uso de `test-config.json` o `tests-config.json` con el significado equivocado.
- Editar binarios vendored en lugar de actualizarlos desde su fuente.
- Mezclar migración estructural y cambios científicos en el mismo commit.
- Ejecutar `wd-initialization` sobre directorios no descartables.

## 13. Checklist de conformidad

- [ ] El entrypoint tiene el nombre del software y expone `run`, `test` y
      `templates cparams`.
- [ ] El runner resuelve Compi, entorno, logs y marcador de validación.
- [ ] El prelude de `main.xml` respeta el orden canónico.
- [ ] Todos los `id` son únicos y el DAG no tiene ciclos.
- [ ] Todos los parámetros públicos están en XML y en
      `params-examples/compi.parameters`.
- [ ] Todas las rutas dinámicas están en `environment.json` o en EnvHandler.
- [ ] Los directorios `output::*` se crean desde `wd-initialization`.
- [ ] Los scripts usan `source`, `LOAD_PRINTER`, `ENV` y `msg`.
- [ ] Todas las claves `msg` existen en el JSON correspondiente.
- [ ] Los metadatos de parámetros y salidas son coherentes.
- [ ] `test_config.json` y, si aplica, `tests-config.json` son válidos.
- [ ] `bash -n`, `xmllint` y la validación JSON pasan.
- [ ] El test pequeño produce las mismas salidas que la línea base.
