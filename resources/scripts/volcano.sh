#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

contrast_label=$(echo "${comparison}" | cut -d'"' -f2 )

function run_volcano {
	# $1 : counts file
	# $2 : output directory
	# $3 : contrast label
	# $4 : software
	# $5 : EnvHandler output key
	msg volcano.BUILDING "software=${4}"
	run_container r_enhanced-volcano Rscript "${pipelineDir}/${scriptsDir}/${enhancedVolcanoRscript}" "${1}" "${2}" "${3}" "${4}"
	local volcano_file="${2}${3}_volcano.pdf"
	if [[ -f "${volcano_file}" ]]; then
		register_output "volcano:${4}_${3}" "${volcano_file}" "${5}"
	fi
}

function test_and_run {
	# $1 : counts file
	# $2 : output directory
	# $3 : contrast label
	# $4 : software
	# $5 : EnvHandler output key
	# $6 : display name
	if [[ -f "$1" ]]; then
		run_volcano "$1" "$2" "$3" "$4" "$5"
	else
		msg volcano.NO_RESULTS "software=$6"
		msg common.DONE
	fi
}

if [[ ${selectDEAsoftware} == 'edger' ]] || [[ ${selectDEAsoftware} == 'both' ]]; then
	path_output_docker=$(get_output_dir edger "${comparison}")
	vp_path_counts="${path_output_docker}/$(echo EdgeR_${contrast_label} | xargs).tsv"
	vp_software="edger"
	test_and_run "${vp_path_counts}" "${path_output_docker}" "${contrast_label}" "${vp_software}" "output::edgOut" "EdgeR"
fi

if [[ ${selectDEAsoftware} == 'deseq' ]] || [[ ${selectDEAsoftware} == 'both' ]]; then
	path_output_docker=$(get_output_dir deseq "${comparison}")
	vp_path_counts="${path_output_docker}/$(echo DESeq2_${contrast_label} | xargs).tsv"
	vp_software="deseq"
	test_and_run "${vp_path_counts}" "${path_output_docker}" "${contrast_label}" "${vp_software}" "output::dsqOut" "DESeq2"
fi

if [[ ${selectDEAsoftware} == 'both' ]]; then
	contrast_name=$(echo "${comparison}" | cut -d'"' -f4 )
	path_output_docker="$(ENV path get-dir output::deaIntOut)/${contrast_label}/"
	vp_path_counts="${path_output_docker}/DEmiRNAs_${contrast_name}_deseq-edger_integrated.tsv"
	vp_software="both"
	test_and_run "${vp_path_counts}" "${path_output_docker}" "${contrast_label}" "${vp_software}" "output::deaIntOut" "integrated"
fi
