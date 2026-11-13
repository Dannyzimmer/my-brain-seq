#!/bin/bash
#
# WARNING: Requires the LOGGER function (set by environment.sh) and the variable
# MESSAGES_JSON (environment.sh > LOAD_TESTS):
#
#   MESSAGES_JSON="resources/data/msg_tests.json"
#   _MSG="${pipelineDir}/${LoggerScr}"
#   LOGGER(){
#      "${_MSG}" "${@}"
#   }

set -o nounset

_TEST_NAME_MAX_WIDTH=20

die() {
    # Use for raise an error if a test does not returns 0
    # Example:
    #      test_x  || die
    local code=${1:-1}
    exit "$code"
    return 1
}

print_ok() {
  local test_name="$1"   # the name to display in the fixed-width field
  local width=$_TEST_NAME_MAX_WIDTH
  local green="\e[32m"
  local reset="\e[0m"
  local left_padding="$(indent_message "")"

  printf "%b${left_padding}>>[TEST][%-*.*s][OK]%b\n" \
    "$green" \
    "$width" "$width" "$test_name" \
    "$reset"
}

print_error() {
    local test_name="$1"
    local message="$2"
    local width="$_TEST_NAME_MAX_WIDTH"
    local red="\e[31m"
    local reset="\e[0m"
    local left_padding="$(indent_message "")"

    # %-*.*s pads or truncates test_name to width
    printf "%b${left_padding}>>[TEST][%-*.*s][ERROR]: %s%b\n" \
        "$red" \
        "$width" "$width" "$test_name" \
        "$message" \
        "$reset" \
        >&2
}

get_text_len() {
    local text="${1}"
    local cleaned_text
    cleaned_text="$(echo "${text}" | sed -r 's/\x1B(\[[0-9;]*[JKmsu]|\(B)//g' | wc -m)"
    echo "${cleaned_text}"
}

indent_message() {
    local message="$1"
    local header="[TEST]$_HEADER "
    local header_len
    header_len=$(get_text_len "${header}")

    local indentation
    indentation=$(printf '%*s' "${header_len}" "")
    echo "${message}" | sed "s/^/${indentation}/"
}

test_passed(){
    local test_name="$1"
    print_ok "$test_name"
}

test_failed(){
    local test_name="$1"
    local message="$2"
    print_error "$test_name" "$message"
}

test_msg(){
    export MESSAGES_JSON="${pipelineDir}/${msgDir}/${msgTests}"  #FIXME?
    local log_path="$1"
    shift
    local test_name="${log_path%%.*}"
    local raw="$(LOGGER get $log_path "$@")"
    # remove linebreaks
    local message="${raw//$'\n'/ }"
    local severity="$(LOGGER get-severity $log_path)"
    if [[ $severity == "error" ]]; then
        print_error "$test_name" "$message"
    else
        print_ok "$test_name"
    fi
}

test_msg_custom() {
    export MESSAGES_JSON="${pipelineDir}/${msgDir}/${msgTests}"  # FIXME?
    local test_name="$1"
    local log_path="$2"
    shift 2
    local raw
    raw="$(LOGGER get "$log_path" "$@")"
    # Remove line breaks
    local message="${raw//$'\n'/ }"
    local severity
    severity="$(LOGGER get-severity "$log_path")"
    if [[ "$severity" == "error" ]]; then
        print_error "$test_name" "$message"
    else
        print_ok "$test_name"
    fi
}

is_errexit_on() {
  case "$-" in
    *e*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

variable_exists(){
    # E.g.: variable_exists LUSTRE_SCRATCH hpc.LUSTRE
    # E.g.: variable_exists LUSTRE_SCRATCH hpc.LUSTRE path=$some_path
    local var_name="$1"   # Variable name, without the $
    local log_path="$2"   # namespace.key
    shift 2
    local message="$(LOGGER get $log_path $@)"

    if [ -z "${!var_name+x}" ]; then
        test_msg "$log_path"
        return 1
    else
        return 0
    fi
}

is_slurm_avail(){
    if which sinfo >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

test_slurm_avail(){
    if which sinfo >/dev/null 2>&1; then
        test_msg "slurm.SUCCESS"
        return 0
    else
        test_msg "slurm.SLURM_UNAVAILABLE"
        return 1
    fi
}

test_slurm_env(){
    if is_slurm_avail; then
        variable_exists "LOCAL_SCRATCH" "slurm.LOCAL_SCRATCH_UNAVAILABLE"
    fi
}

test_slurm_singularity() {
    # Assumes Slurm availability (test with `test_slurm_avail`)
    if is_slurm_avail; then
        if module load singularity >/dev/null 2>&1; then
            test_msg "singularity_slurm.SUCCESS"
            return 0
        else
            test_msg "singularity_slurm.SINGULARITY_MODULE_NOT_AVAILABLE" 
            return 1
        fi
    fi
}

test_slurm(){
    if is_slurm_avail; then
        test_slurm_env
        test_slurm_singularity
    fi
}


test_user_fasta_file() {
    local file="$1"
    local test_name="${2:-fasta_file}"

    # 1) Check that a filename was provided
    if [[ -z "$file" ]]; then
        test_msg_custom "${test_name}" fasta_file.REQUIRES_FILENAME
        return 1
    fi

    # 2) Check if the file exists and is a regular file
    if [[ ! -f "$file" ]]; then
        test_msg_custom "${test_name}" fasta_file.MISSING
        return 1
    fi

    # 3) Check file extension
    if [[ ! "$file" =~ \.(fasta|fa|fas|fna)$ ]]; then
        file_extension="${file##*.}"
        test_msg_custom "${test_name}" fasta_file.INVALID_EXTENSION "file_extension=$file_extension"
        return 1
    fi

    # 4) Check that the first line starts with '>'
    if ! head -n1 "$file" | grep -q '^>'; then
        test_msg_custom "${test_name}" fasta_file.INVALID_FORMAT
        return 1
    fi

    # 5) If we reach here, the file exists and has a valid FASTA header
    test_msg_custom "${test_name}" fasta_file.SUCCESS
    return 0
}

test_json(){
    local file="${1}"

    # 1) Check if the file exists and is a regular file
    if [[ ! -f "$file" ]]; then
        test_msg test_json.MISSING_FILE "file=$file"
        return 1
    fi

    # 2) Check that the file is valid JSON
    if ! jq -e . "$file" > /dev/null 2>&1; then
        test_msg test_json.INVALID_JSON "file=$file"
        return 1
    fi

    # 3) All checks passed
    test_msg test_json.SUCCESS
    return 0
}

test_singularity_json() {
    local file="${1:-${singularityJSON}}"
    shift || true
    local key
    local required_keys=("$@")

    # 1) Check if the file exists and is a regular file
    if [[ ! -f "$file" ]]; then
        test_msg singularity_json.MISSING_FILE "file=$file"
        return 1
    fi

    # 2) Check that the file is valid JSON
    if ! jq -e . "$file" > /dev/null 2>&1; then
        test_msg singularity_json.INVALID_JSON "file=$file"
        return 1
    fi

    # 3) Check for each required key in the JSON
    for key in "${required_keys[@]}"; do
        if ! jq -e "has(\"$key\")" "$file" > /dev/null; then
            test_msg singularity_json.MISSING_KEY "key=$key"
            return 1
        fi
    done

    # 4) All checks passed
    test_msg singularity_json.SUCCESS
    return 0
}

test_sudo_on() {
    # 1) Check if running with root privileges (i.e. under sudo)
    if [[ $EUID -ne 0 ]]; then
        test_msg sudo_on.REQUIRES_SUDO
        return 1
    else
        test_msg sudo_on.SUCCESS
        return 0
    fi
}

test_singularity_avail(){
    if command -v singularity &>/dev/null; then
        test_msg singularity_cmd.SUCCESS
    else
        test_msg singularity_cmd.SINGULARITY_NOT_IN_PATH
        return 2
    fi
}

test_local(){
    if ! is_slurm_avail; then
        test_singularity_avail
    fi
}

test_singularity_image() {
    # Assumes Singularity availability (test with `test_singularity_avail`)
    local image="$1"
    local image_name="$2"
    shift 2
    local cmd=( "$@" )

    # Usage check
    if [[ -z "$image" || ${#cmd[@]} -eq 0 ]]; then
        test_msg_custom "$image_name" singularity_cmd.USAGE
        return 1
    fi

    # Check image file exists and is readable
    if [[ ! -f "$image" ]]; then
        test_msg_custom "$image_name" singularity_cmd.IMAGE_NOT_FOUND "image_path=$image"
        return 3
    fi

    # 3) Execute the command inside the image
    singularity exec "$image" "${cmd[@]}" >/dev/null 2>&1
    local status=$?

    if [[ $status -eq 0 ]]; then
        test_msg_custom "$image_name" singularity_cmd.SUCCESS
        return 0
    else
        test_msg_custom "$image_name" singularity_cmd.COMMAND_EXITED "exit_code=$status"
        return $status
    fi
}

test_dir_exists(){
    local dir_path="$1"
    local test_name="${2:-dir_exists}"

    if [[ -d "$dir_path" ]]; then
        test_msg_custom "$test_name" directory.SUCCESS "dir_path=$dir_path"
        return 0
    else
        test_msg_custom "$test_name" directory.MISSING "dir_path=$dir_path"
        return 1
    fi
}

# PARAMETER CHECKS
require_one_option() {
    # Ensure that exactly one of the provided options is set to a non-FALSE value.
    # Usage:
    #   param_A="TRUE"
    #   param_B="TRUE"
    #   param_C="FALSE"
    #   require_one_option test_name OPTION_A OPTION_B OPTION_C

    local name value
    local count=0
    local false_options=()
    local non_false_options=()
    local test_name="${1:-choice}"
    shift

    for name in "$@"; do
        value=${!name-}
        if [[ "$value" != "FALSE" ]]; then
            ((count += 1))
            non_false_options+=("$name")
        else
            false_options+=("$name")
        fi
    done

    if ((count > 1)); then
        # Multiple selected options.
        test_msg_custom "$test_name" parameters.PARAMS_MULTIPLE_CHOICE_ERROR \
            "parameters=${non_false_options[*]}"

    elif ((count == 0)); then
        # No selected options.
        test_msg_custom "$test_name" parameters.PARAMS_UNDEFINED_CHOICE_ERROR \
            "params=${false_options[*]}"

    else
        # Exactly one selected option.
        test_msg_custom "$test_name" parameters.PARAMS_OK
    fi
}

require_all_options() {
    # Ensure that all of the provided options are set to a non-FALSE value.
    # Usage:
    #   param_A="TRUE"
    #   param_B="TRUE"
    #   param_C="FALSE"
    #   require_all_options OPTION_A OPTION_B OPTION_C

    local name value
    local missing_options=()
    local test_name="required params"

    for name in "$@"; do
        value=${!name-}
        if [[ "$value" == "FALSE" ]]; then
            missing_options+=("$name")
        fi
    done

    if (( ${#missing_options[@]} > 0 )); then
        test_msg_custom "$test_name" parameters.PARAMS_MISSING_ERROR \
            "parameters=${missing_options[*]}"
    else
        test_msg_custom "$test_name" parameters.PARAMS_OK
    fi
}
