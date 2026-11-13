#!/bin/bash
#===============================================================================
# WARNING:
# Variables and functions set on this file will ve available to all the tasks
# of the pipeline.
#===============================================================================

# ENVIRONMENT MANAGEMENT =======================================================
# Set _ENVIRONMENT_DB_PATH variable to change the default path for the database
export _ENVIRONMENT_DB_PATH="${workingDir}/environment.db"
_ENV_SCRIPT="${pipelineDir}/${envHandler}"

ENV() {
    "${_ENV_SCRIPT}" "${@}"
}
# ==============================================================================

# LOGGER (log management) ======================================================
_MSG="${pipelineDir}/${LoggerScr}"
LOGGER(){
    "${_MSG}" "${@}"
}
# ==============================================================================

# SIFManager (Singularity image management) ====================================
_ENV_HEADER="[MYBRAINSEQ][${task_id:-}]"
_HEADER_INDENT=$(printf "%*s" "${#_ENV_HEADER}" "")
_SIF_MANAGER="${pipelineDir}/${sifManagerBin}"
SIF_MANAGER(){
  if [[ "$1" == "--indented" ]]; then
    shift
    INDENT_CALL "${_SIF_MANAGER}" "$@"
  else
    "${_SIF_MANAGER}" "$@"
  fi
}
# ==============================================================================

# PYTHONPATH ===================================================================
# Adds vendor directory to the PYTHONPATH
PYTHONPATH="${pipelineDir}/${vendorDir}${PYTHONPATH:+:$PYTHONPATH}"
export PYTHONPATH
# ==============================================================================

INDENT_CALL(){
    # Run a command in a subshell, indenting its output and managing errors
    # Example: INDENT_CALL echo "Hello World"
    local header="[MYBRAINSEQ][${task_id:-}]"
    local indentation=$(printf "%*s" "${#header}" "")
    local extra_spaces="  "
    (
        set -o pipefail
        stdbuf -oL "$@" 2>&1 \
            | awk -v ind="${indentation}${extra_spaces}" \
            '{ print ind $0; fflush() }'
    )
}


LOAD_TESTS() {
    source "${pipelineDir}/${testsScr}"
}

LOAD_PRINTER() {
    export MESSAGES_JSON="${pipelineDir}/${msgDir}/${msgMain}"
    source "${pipelineDir}/${printerScr}"
}

_load_singularity_slurm_env() { #FIXME: LOCAL_SCRATCH exclusive of CESGA FT-III??
    module load singularity
    export singularity_home="${LOCAL_SCRATCH}"
    export SINGULARITY_CACHEDIR="${LOCAL_SCRATCH}"
    export SINGULARITY_TMPDIR="${LOCAL_SCRATCH}"
    export TMPDIR="${LOCAL_SCRATCH}"
}

_load_singularity_local_env() {
    export LC_ALL=C
    export singularity_home="${HOME}"
    export TMPDIR="/tmp"
}

LOAD_SINGULARITY_ENV() {
    if [[ "$(ENV param get slurm_available)" == "true" ]]; then
        _load_singularity_slurm_env
    else
        _load_singularity_local_env
    fi
}

STDOUT_OFF(){
    if [[ -z "${verbose+x}" ]]; then
        exec 3>&1
        exec > /dev/null
    else
        echo ""
    fi
}

STDOUT_ON(){
    if [[ -z "${verbose+x}" ]]; then
        exec >&3
    fi
}

GET_PIPELINE_PARAM() {
    # Returns the defaultValue for the <param> with name="$1" in the specified XML file.
    local param_name="$1"
    local pipeline_path="${2}"

    # Validate arguments
    if [[ -z "$param_name" ]]; then
        echo "Usage: GET_PIPELINE_PARAM <param_name> [path_to_main.xml]" >&2
        return 1
    fi
    if [[ ! -f "$pipeline_path" ]]; then
        echo "ERROR: XML file '$pipeline_path' not found." >&2
        return 2
    fi

    # Extract defaultValue using xmllint (namespace-agnostic)
    xmllint --xpath \
      "string(//*[local-name()='param' and @name='${param_name}']/@defaultValue)" \
      "$pipeline_path"
}
