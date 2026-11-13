# Helpers shared by the scientific scripts.

# Resolve a pipeline-relative path (e.g. /resources/data/databases/) or an
# absolute user path.
function resolve_pipeline_path {
	local path="$1"
	if [[ "${path}" == /resources/* ]]; then
		echo "${pipelineDir}${path}"
	elif [[ "${path}" != /* ]]; then
		echo "${pipelineDir}/${path}"
	else
		echo "${path}"
	fi
}

# Build the list of host paths that must be visible inside the container.
function _container_binds {
	local -a binds=()
	local path
	for path in "${workingDir}" "${pipelineDir}" "${fastqDir:-}" "${databasesDir:-}"; do
		[[ -n "${path}" && -e "${path}" ]] && binds+=("${path}")
	done
	for path in "${gffFile:-}" "${conditions:-}" "${contrast:-}" "${bwtIndex:-}" "${genome:-}"; do
		if [[ -n "${path}" && -e "$(dirname "${path}")" ]]; then
			binds+=("$(dirname "${path}")")
		fi
	done
	local -a unique=()
	local candidate
	for candidate in "${binds[@]}"; do
		local seen=0
		local item
		for item in "${unique[@]}"; do
			if [[ "${item}" == "${candidate}" ]]; then
				seen=1
				break
			fi
		done
		(( seen )) || unique+=("${candidate}")
	done
	local IFS=','
	echo "${unique[*]}"
}

# Run a command inside the Singularity image registered as singularity::<key>.
function run_container {
	local container_key="$1"
	shift
	local image
	image="$(ENV param get "singularity::${container_key}")"
	local bind_paths
	bind_paths="$(_container_binds)"
	LOAD_SINGULARITY_ENV
	singularity exec --pwd / --bind "${bind_paths}" "${image}" "$@"
}

# Register a produced file in EnvHandler.
function register_output {
	local key="$1"
	local path="$2"
	local parent="$3"
	ENV path add-file --force "${key}" "${path}" "${parent}"
}

# Return the EnvHandler output key associated with a differential expression
# software name.
function software_output_key {
	case "$1" in
		EdgeR)         echo "output::edgOut" ;;
		DESeq2)        echo "output::dsqOut" ;;
		DESeq2-EdgeR)  echo "output::deaIntOut" ;;
		*)             echo "output::deaIntOut" ;;
	esac
}

# Get the output path for the files saved in 6_deseq2 and 6_edger directories.
# Usage: result=$(get_output_dir deseq "${comparison}")
function get_output_dir {
	local software="$1"
	local comparison="$2"
	local comparison_label
	comparison_label=$(echo "$comparison" | cut -d'=' -f1 | tr -d '\"' | xargs)
	local soft_dir
	if [[ "${software}" == 'deseq' ]]; then
		soft_dir="${dsqOut}"
	elif [[ "${software}" == 'edger' ]]; then
		soft_dir="${edgOut}"
	fi
	echo "${workingDir}/${outDir}/${soft_dir}/${comparison_label}/"
}
