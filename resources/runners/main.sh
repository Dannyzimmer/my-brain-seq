#!/bin/bash
#
# Run the myBrainSeq pipeline
#  - $1 : Path to compi.parameters file
#  - $2 : Path to the XML of the pipeline
#  - $3 : Pipeline root path
#  - $4... : Additional Compi parameters (optional)

set -o nounset
set -o errexit
set -o pipefail

function get_compi_parameter() {
    grep -E "^${2}=" "${1}" | cut -d'=' -f2-
}

function show_error() {
  echo "ERROR: $*" >&2
  echo "Usage:"
  echo "  $0 <params-file> <pipeline-path> [additional compi args...]"
  exit 1
}

function get_pipeline_param() {
    local param_name="$1"
    local pipeline_path="${PIPELINE_XML}"

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


# Check at least two arguments
if [[ $# -lt 2 ]]; then
  show_error "Insufficient arguments provided."
fi

# MANDATORY INPUTS OF THE RUNNER
PARAM_FILE="$1"
PIPELINE_XML="$2"
ROOT="$3"
shift 3
general_opts=()
pipeline_opts=()

if [[ ! -f "${PARAM_FILE}" ]]; then
  show_error "The parameters file (${PARAM_FILE}) does not exist."
fi
PARAM_FILE="$(realpath "${PARAM_FILE}")"

# OPTIONAL ARGS OF THE RUNNER
# Format:
# <compi_options> -- <pipeline_parameters>
# <compi_options>
# -- <pipeline_parameters>
#
while [ "$#" -gt 0 ]; do
  case "$1" in
    --)
      shift  # remove '--'
      break  # remains pipeline_opts ($@)
      ;;
    *)
      general_opts+=("$1")
      shift
      ;;
  esac
done

pipeline_opts=("$@")

# Variables
PIPELINE_VERSION="latest"
COMPI_RUNNER="${ROOT}/$(get_pipeline_param compiDir)/compi"
SHARE_DIR="${ROOT}/$(get_pipeline_param shareDir)"
ENVIRONMENT_FILE="${SHARE_DIR}/environment.sh"

# Default pipeline params
pipeline_opts+=( \
  --pipelineDir "$ROOT" \
  --environment "$ENVIRONMENT_FILE" \
  --compiParameters "$PARAM_FILE" \
)

# Extract workingDir
workingDir="$(get_compi_parameter "${PARAM_FILE}" "workingDir")"
VALIDATION_MARKER="${workingDir}/.parameter_validation_failed"
rm -f "${VALIDATION_MARKER}"

# Timestamp and logs
timestamp=$(date +"%Y-%m-%d_%H.%M.%S")
mkdir -p "${workingDir}/logs/${timestamp}"

# Run the pipeline
set +e
bash "${COMPI_RUNNER}" run \
    -p "${PIPELINE_XML}" \
    --logs "${workingDir}/logs/${timestamp}/tasks" \
    -pa "${PARAM_FILE}" \
    -o \
    "${general_opts[@]}" \
    -- \
    "${pipeline_opts[@]}" \
  2>&1 | tee "${workingDir}/logs/${timestamp}/compi.log"
COMPI_STATUS=${PIPESTATUS[0]}
set -e

if [[ -f "${VALIDATION_MARKER}" ]]; then
    rm -f "${VALIDATION_MARKER}"
    exit 1
fi

exit "${COMPI_STATUS}"
