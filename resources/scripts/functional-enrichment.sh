#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg functional_enrichment.STARTING

function run_functional_enrichment {
	# $1 : tarbase db
	# $2 : reactome db
	# $3 : dea result file
	# $4 : input contrast
	# $5 : software
	# $6 : db organism
	# $7 : path output
	# $8 : qvalue
	msg functional_enrichment.PERFORMING "software=${5}"
	run_container r_data-analysis Rscript "${pipelineDir}/${scriptsDir}/${functionalEnrichmentRscript}" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
}

function test_and_run {
	# $1 : tarbase db
	# $2 : reactome db
	# $3 : dea result file
	# $4 : input contrast
	# $5 : software
	# $6 : db organism
	# $7 : path output
	# $8 : display name
	# $9 : qvalue
	if [[ -f "$3" ]]; then
		run_functional_enrichment "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$9"
		local contrast_name
		contrast_name=$(echo "$4" | cut -d'"' -f4)
		local table_file="${7}enrichment_table_${5}_${contrast_name}.tsv"
		local plot_file="${7}enriched_reactome_words_${5}_${contrast_name}.pdf"
		local parent_key
		parent_key="$(software_output_key "$5")"
		if [[ -f "${table_file}" ]]; then
			register_output "functional:${5}_${contrast_name}_table" "${table_file}" "${parent_key}"
		fi
		if [[ -f "${plot_file}" ]]; then
			register_output "functional:${5}_${contrast_name}_plot" "${plot_file}" "${parent_key}"
		fi
	else
		msg functional_enrichment.NO_RESULTS "software=$8"
		msg common.DONE
	fi
}

contrast_label=$(echo "${comparison}" | cut -d'"' -f2 )

databases_dir="$(resolve_pipeline_path "${databasesDir}")"
tarbase_db_file="${databases_dir}/${tarbaseDB}"
reactome_db_file="${databases_dir}/${reactomeDB}"
input_contrast="${comparison}"
db_organism="${organism}"

if [[ ${selectDEAsoftware} == 'edger' ]] || [[ ${selectDEAsoftware} == 'both' ]]; then
	path_output=$(get_output_dir edger "${comparison}")
	dea_result_file="${path_output}/$(echo EdgeR_${contrast_label} | xargs).tsv"
	software="EdgeR"
	test_and_run "${tarbase_db_file}" "${reactome_db_file}" "${dea_result_file}" "${input_contrast}" "${software}" "${db_organism}" "${path_output}" 'EdgeR' "${qvalue}"
fi

if [[ ${selectDEAsoftware} == 'deseq' ]] || [[ ${selectDEAsoftware} == 'both' ]]; then
	path_output=$(get_output_dir deseq "${comparison}")
	dea_result_file="${path_output}/$(echo DESeq2_${contrast_label} | xargs).tsv"
	software="DESeq2"
	test_and_run "${tarbase_db_file}" "${reactome_db_file}" "${dea_result_file}" "${input_contrast}" "${software}" "${db_organism}" "${path_output}" 'DESeq2' "${qvalue}"
fi

if [[ ${selectDEAsoftware} == 'both' ]]; then
	contrast_name=$(echo "${comparison}" | cut -d'"' -f4 )
	path_output="$(ENV path get-dir output::deaIntOut)/${contrast_label}/"
	dea_result_file="${path_output}/DEmiRNAs_${contrast_name}_deseq-edger_integrated.tsv"
	software='DESeq2-EdgeR'
	test_and_run "${tarbase_db_file}" "${reactome_db_file}" "${dea_result_file}" "${input_contrast}" "${software}" "${db_organism}" "${path_output}" 'integrated' "${qvalue}"
fi
