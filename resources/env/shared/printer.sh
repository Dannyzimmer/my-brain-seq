#------------------------------------------------------------------------------#
#                                                                              #
#                A SET OF PRINT FUNCTIONS TO USE WITH LOGGER                   #
#                                                                              #
#                                                               (c) Dannyzimm  #
#------------------------------------------------------------------------------#
# REQUIRES GLOBAL VARIABLE WITH THE PATH TO THE JSON WITH THE MESSAGES
#     export MESSAGES_JSON="example/path/to/messages.json"
#-------------------------------------------------------------------------------

_HEADER="[MYBRAINSEQ][${task_id}]"

print_info() {
    local message="$1"
    echo "${_HEADER}[INFO]: ${message}"
}

print_warning() {
    local message="$1"
    echo "${_HEADER}[WARNING]: ${message}"
}

print_error() {
    local message="$1"
    echo "${_HEADER}[ERROR]: ${message}"
}

print_fatal() {
    local message="$1"
    echo "${_HEADER}[FATAL]: ${message}"    
}

get_text_len() {
    local text="${1}"
    local cleaned_text
    cleaned_text="$(echo "${text}" | sed -r 's/\x1B(\[[0-9;]*[JKmsu]|\(B)//g' | wc -m)"
    echo "${cleaned_text}"
}

indent_message() {
    local message="$1"
    local header="$_HEADER [     ]"
    local header_len
    header_len=$(get_text_len "${header}")

    local indentation
    indentation=$(printf '%*s' "${header_len}" "")
    echo "${message}" | sed "s/^/${indentation}/"
}

#-------------------------------------------------------------------------------
# MAIN FUNCTION TO CALL: msg
# Examples:
#    # basic use
#    msg "singularity_slurm.SUCCESS"
#
#    # using placeholders
#    msg fastq_filenames.FASTQ_NONE_FOUND "directory=$fastqDir"
#    msg filesystem.FS_NO_LINKS "fstype=${fstype}" "mountpoint=${path}"
#-------------------------------------------------------------------------------
indent() { sed 's/^/      /'; }

msg(){
    export MESSAGES_JSON="${pipelineDir}/${msgDir}/${msgMain}"  #FIXME?
    local suppress_header=0

    # parse a "-i" flag:
    if [[ "$1" == "-i" ]]; then
        suppress_header=1
        shift
    fi

    local log_path="$1"; shift
    local message="$(LOGGER get "$log_path" "$@")"
    local severity="$(LOGGER get-severity "$log_path")"
    local indented
    indented="$(LOGGER is-indented "$log_path")"


    # if indent mode, no header
    if [[ $indented == "True" ]]; then
        indent_message "${message}"
        return 0
    fi

    # otherwise
    case "$severity" in
        info)    print_info    "$message" ;;
        warning) print_warning "$message" ;;
        error)   print_error   "$message" ;;
        fatal)   print_fatal   "$message" ;;
        *)       return 1 ;;
    esac
}
