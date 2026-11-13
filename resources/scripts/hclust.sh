#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

contrast_label=$(echo "${comparison}" | cut -d'"' -f2 )
contrast_label_samples=$(echo "${comparison}" | cut -d'"' -f4 )

function run_deseq2_normalization {
	# $1 : path_counts
	# $2 : path_conditions
	# $3 : path_output
	# $4 : software
	# $5 : input_contrast
	msg hclust.NORMALIZING
	run_container r_deseq2 Rscript "${pipelineDir}/${scriptsDir}/${deseq2NormalizationRscript}" "${1}" "${2}" "${3}" "${4}" "${5}"
	local normalized_file="${3}all-counts_${4}_${contrast_label}_normalized.txt"
	if [[ -f "${normalized_file}" ]]; then
		register_output "hclust:${4}_${contrast_label}_normalized" "${normalized_file}" "$(software_output_key "${4}")"
	fi
}

function run_hclust_make-table {
	# $1 : dea_results
	# $2 : path_counts
	# $3 : path_conditions
	# $4 : input_contrast
	# $5 : path_output_pipel
	# $6 : software
	# $7 : qvalue
	# $8 : log2FC
	msg hclust.BUILDING_TABLE "software=${6}"
	run_container r_data-analysis Rscript "${pipelineDir}/${scriptsDir}/${hclustMakeTableRscript}" "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "${7}" "${8}"
	local hclust_file="${5}hclust_${6}_${contrast_label}.tsv"
	if [[ -f "${hclust_file}" ]]; then
		register_output "hclust:${6}_${contrast_label}_table" "${hclust_file}" "$(software_output_key "${6}")"
	fi
}

function run_hclust {
	# $1 : path_hclust_file
	# $2 : input_contrast
	# $3 : path_output
	# $4 : software
	# $5 : conditions_file
	# $6 : distance_method
	msg hclust.RUNNING "software=${4}"
	run_container r_data-analysis Rscript "${pipelineDir}/${scriptsDir}/${hclustRscript}" "${1}" "${2}" "${3}" "${4}" "${5}" "${6}"
	local contrast_name
	contrast_name=$(echo "${2}" | cut -d'"' -f4)
	local dendrogram_file="${3}dendrogram_${4}_${contrast_name}.pdf"
	local heatmap_file="${3}heatmap_${4}_${contrast_name}.pdf"
	local parent_key
	parent_key="$(software_output_key "${4}")"
	if [[ -f "${dendrogram_file}" ]]; then
		register_output "hclust:${4}_${contrast_name}_dendrogram" "${dendrogram_file}" "${parent_key}"
	fi
	if [[ -f "${heatmap_file}" ]]; then
		register_output "hclust:${4}_${contrast_name}_heatmap" "${heatmap_file}" "${parent_key}"
	fi
}

function test_and_run_hclust {
	# $1 : path_hclust_file
	# $2 : input_contrast
	# $3 : path_output
	# $4 : software
	# $5 : conditions_file
	# $6 : distance_method
	if [[ -f "$1" ]]; then
		run_hclust "${1}" "${2}" "${3}" "${4}" "${5}" "${6}"
	else
		msg hclust.NO_TABLE "software=$4"
		msg hclust.SKIPPING
	fi
}

function test_and_run {
	# $1 : dea_results
	# $2 : path_counts
	# $3 : path_conditions
	# $4 : input_contrast
	# $5 : path_output_docker
	# $6 : software
	# $7 : display name
	# $8 : path_hclust_file
	# $9 : path_output_pipel
	# $10 : distance_method
	# $11 : qvalue
	# $12 : log2FC
	if [[ -f "$1" ]]; then
		run_hclust_make-table "${1}" "${2}" "${3}" "${4}" "${9}" "${6}" "${11}" "${12}"
		test_and_run_hclust "${8}" "${4}" "${5}" "${6}" "${3}" "${10}"
	else
		msg hclust.NO_RESULTS "software=$6"
		msg common.DONE
	fi
}

path_conditions="${conditions}"
input_contrast="${comparison}"
path_counts="$(ENV path get-dir output::ftqOut)/all-counts.txt"

if [[ -v ${1} ]]; then
	if [[ ${selectDEAsoftware} == 'edger' ]] || [[ ${selectDEAsoftware} == 'both' ]]; then
		path_output_normalized_counts="$(get_output_dir edger "${comparison}")/pipel/"
		software="EdgeR"
		run_deseq2_normalization "${path_counts}" "${path_conditions}" "${path_output_normalized_counts}" "${software}" "${input_contrast}"
	fi

	if [[ ${selectDEAsoftware} == 'deseq' ]] || [[ ${selectDEAsoftware} == 'both' ]]; then
		path_output_normalized_counts="$(get_output_dir deseq "${comparison}")/pipel/"
		software="DESeq2"
		run_deseq2_normalization "${path_counts}" "${path_conditions}" "${path_output_normalized_counts}" "${software}" "${input_contrast}"
	fi

	if [[ ${selectDEAsoftware} == 'both' ]]; then
		path_output_normalized_counts="$(ENV path get-dir output::deaIntOut)/${contrast_label}/pipel/"
		software="DESeq2-EdgeR"
		run_deseq2_normalization "${path_counts}" "${path_conditions}" "${path_output_normalized_counts}" "${software}" "${input_contrast}"
	fi
fi

if [[ ${selectDEAsoftware} == 'edger' ]] || [[ ${selectDEAsoftware} == 'both' ]]; then
	path_output_docker=$(get_output_dir edger "${comparison}")
	path_output_pipel="${path_output_docker}/pipel/"
	dea_results="${path_output_docker}/$(echo EdgeR_${contrast_label} | xargs).tsv"
	software="EdgeR"

	if [[ -v ${1} ]]; then
		path_counts="${path_output_pipel}/all-counts_${software}_${contrast_label}_normalized.txt"
	else
		path_counts="${path_output_docker}/pipel/$(echo all-counts_edger_${contrast_label} | xargs).txt"
	fi

	path_hclust_file="${path_output_pipel}/$(echo hclust_EdgeR_${contrast_label} | xargs).tsv"
	test_and_run "${dea_results}" "${path_counts}" "${path_conditions}" "${input_contrast}" "${path_output_docker}" "${software}" 'EdgeR' "${path_hclust_file}" "${path_output_pipel}" "${distance_method}" "${qvalue}" "${log2FC}"
fi

if [[ ${selectDEAsoftware} == 'deseq' ]] || [[ ${selectDEAsoftware} == 'both' ]]; then
	path_output_docker=$(get_output_dir deseq "${comparison}")
	path_output_pipel="${path_output_docker}/pipel/"
	dea_results="${path_output_docker}/$(echo DESeq2_${contrast_label} | xargs).tsv"
	software="DESeq2"

	if [[ -v ${1} ]]; then
		path_counts="${path_output_pipel}/all-counts_${software}_${contrast_label}_normalized.txt"
	else
		path_counts="${path_output_docker}/pipel/$(echo all-counts_deseq_${contrast_label} | xargs).txt"
	fi

	path_hclust_file="${path_output_pipel}/$(echo hclust_DESeq2_${contrast_label} | xargs).tsv"
	test_and_run "${dea_results}" "${path_counts}" "${path_conditions}" "${input_contrast}" "${path_output_docker}" "${software}" 'DESeq2' "${path_hclust_file}" "${path_output_pipel}" "${distance_method}" "${qvalue}" "${log2FC}"
fi

if [[ ${selectDEAsoftware} == 'both' ]]; then
	path_output_docker="$(ENV path get-dir output::deaIntOut)/${contrast_label}/"
	path_output_pipel="${path_output_docker}/pipel/"
	dea_results="${path_output_docker}/DEmiRNAs_${contrast_label_samples}_deseq-edger_integrated.tsv"
	software="DESeq2-EdgeR"

	path_output_edger_docker=$(get_output_dir edger "${comparison}")
	path_output_edger_pipel="${path_output_edger_docker}/pipel/"

	if [[ -v ${1} ]]; then
		path_counts="${path_output_edger_pipel}/all-counts_EdgeR_${contrast_label}_normalized.txt"
	else
		path_counts="${path_output_edger_docker}/pipel/$(echo all-counts_edger_${contrast_label} | xargs).txt"
	fi

	path_hclust_file="${path_output_pipel}/$(echo hclust_DESeq2-EdgeR_${contrast_label} | xargs).tsv"
	test_and_run "${dea_results}" "${path_counts}" "${path_conditions}" "${input_contrast}" "${path_output_docker}" "${software}" 'integrated' "${path_hclust_file}" "${path_output_pipel}" "${distance_method}" "${qvalue}" "${log2FC}"
fi
