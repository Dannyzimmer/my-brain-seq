#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

METADATA_FILE="${pipelineDir}/${parametersMetadata}"
BRIDGE="${pipelineDir}/${scriptsDir}/compipar_bridge.py"
PARAMS_FILE="${compiParameters}"
VALIDATION_MARKER="${workingDir}/.parameter_validation_failed"

print_validation_line() {
    local level="$1"
    local identifier="$2"
    local message="$3"
    local color=""
    local reset=$'\e[0m'

    case "${level}" in
        OK) color=$'\e[32m' ;;
        WARNING) color=$'\e[33m' ;;
        ERROR) color=$'\e[31m' ;;
    esac

    local label
    label="$(printf '%-9s' "${level}")"
    if [[ -n "${identifier}" ]]; then
        label+="[${identifier:0:7}] "
    fi
    label+="${message}"

    printf '%b%s%s%b\n' "${color}" "$(indent_message '')" "${label}" "${reset}"
}

msg checks.PARAMS_VALIDATION
rm -f "${VALIDATION_MARKER}"

if ! command -v python3 >/dev/null 2>&1; then
    print_validation_line "ERROR" "validator" "python3 was not found in PATH."
    touch "${VALIDATION_MARKER}"
    exit 1
fi

VALIDATION_STATUS=0
VALIDATION_OUTPUT="$(python3 "${BRIDGE}" --metadata "${METADATA_FILE}" --params "${PARAMS_FILE}")" || VALIDATION_STATUS=$?

had_error=0
had_warning=0

if (( VALIDATION_STATUS != 0 )); then
    print_validation_line "ERROR" "validator" "Validator exited with status ${VALIDATION_STATUS}."
    had_error=1
fi

if [[ -n "${VALIDATION_OUTPUT}" ]]; then
    while IFS=$'\t' read -r level identifier message; do
        [[ -z "${level}" ]] && continue
        case "${level}" in
            WARNING) had_warning=1 ;;
            ERROR) had_error=1 ;;
        esac
        print_validation_line "${level}" "${identifier:-}" "${message:-}"
    done <<< "${VALIDATION_OUTPUT}"
fi

if (( had_error )); then
    touch "${VALIDATION_MARKER}"
    exit 1
fi

if (( had_warning == 0 )); then
    print_validation_line "OK" "" "All parameter constraints satisfied."
fi
