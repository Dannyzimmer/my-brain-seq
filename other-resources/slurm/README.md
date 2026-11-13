# Información
El script `run_test.sh` y el archivo JSON `tests-config.json` sirven para automatizar el lanzamiento de los tests en un servidor con Slurm. Para que el script `run_test.sh` funcione es necesario respetar la siguiente estructura del directorio de test:
```
PipelineName
    ├── test-01
    │   ├── compi.parameters
    │   ├── output
    │   └── run_test.sh
    ├── test-02
    │   ├── compi.parameters
    │   ├── output
    │   └── run_test.sh
    └── tests-config.json
```

En esta estructura, el archivo `tests-config.json` se ubica en la carpeta raíz de los tests de un pipeline. Este archivo JSON contiene la siguiente información:
```json
{
    "pipeline_entrypoint": "/path/to/pipeline/public/cli"
}
```

# Entorno con Tabby
En el caso de que se quiera montar un entorno de test con Tabby, hay varios comandos que, junto con el script `run_test.sh` resultan útiles como "login scripts". Generalmente, lo más cómodo es tener una pestaña dedicada al seguimiento de la cola, otra con acceso a la terminal de comandos y otra que muestre los logs de las ejecuciones. A continuación se detallan los comandos que podría tener cada una de ellas.

## Seguimiento de la cola
Para realizar el seguimiento de los trabajos que mandemos a la cola en intervalos de medio segundo.
```bash
watch -n.5 squeue
```

## Acceso a la terminal
Simplemente será necesario situarse sobre el directorio de los tests, y por conveniencia, listar el directorio.
```bash
cd "${LUSTRE}/ruta/directorio/TEST"
ls -1
```

## Seguimiento de los logs de ejecución
Dado que el script `run_test.sh` guarda el log de salida en un archivo de extensión `log` y que siempre comienza con `LOG`, se puede obtener la salida actualizada de estos archivos usando REGEX. Si además se reserva un directorio para guardar todos los tests de distintos software juntos, se puede usar el siguiente código:
```bash
cd "${LUSTRE}/ruta/directorio/TEST"
clear
find . -type f -name 'LOG_*.log' -print0 | xargs -0 tail -F -n0
```

[[Volver]](../../README.md)