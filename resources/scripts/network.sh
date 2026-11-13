#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg network.STARTING

function run_network {
	# $1 : tarbase db
	# $2 : reactome db
	# $3 : enrichment table
	# $4 : reactome interactions
	# $5 : input contrast
	# $6 : software
	# $7 : db organism
	# $8 : path output
	msg network.CREATING "software=${6}"
	run_container r_network Rscript "${pipelineDir}/${scriptsDir}/${networkRscript}" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
	rm -rf "${8}"/network__R-HSA-*[!\.html]
}

function test_and_run {
	# $1 : tarbase db
	# $2 : reactome db
	# $3 : enrichment table
	# $4 : reactome interactions
	# $5 : input contrast
	# $6 : software
	# $7 : db organism
	# $8 : path output
	# $9 : display name
	if [[ -f "$3" ]]; then
		run_network "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
		local parent_key
		parent_key="$(software_output_key "$6")"
		local file
		for file in "${8}"cytoscape_table_*_"${6}"_*; do
			[[ -f "${file}" ]] || continue
			local file_key
			file_key=$(basename "${file}" | tr -c '[:alnum:]_.-' '_')
			register_output "network:${file_key}" "${file}" "${parent_key}"
		done
		for file in "${8}"network_*_"${6}"_*.html; do
			[[ -f "${file}" ]] || continue
			local file_key
			file_key=$(basename "${file}" | tr -c '[:alnum:]_.-' '_')
			register_output "network:${file_key}" "${file}" "${parent_key}"
		done
	else
		msg network.NO_RESULTS "software=$9"
		msg common.DONE
	fi
}

contrast_label=$(echo "${comparison}" | cut -d'"' -f2 )
contrast_name=$(echo "${comparison}" | cut -d'"' -f4 )

databases_dir="$(resolve_pipeline_path "${databasesDir}")"
path_tarbase_db="${databases_dir}/${tarbaseDB}"
path_reactome_db="${databases_dir}/${reactomeDB}"
path_reactome_interaction="${databases_dir}/${reactomeInteractionsDB}"
input_contrast="${comparison}"
db_organism="${organism}"

if [[ ${selectDEAsoftware} == 'edger' ]] || [[ ${selectDEAsoftware} == 'both' ]]; then
	path_output=$(get_output_dir edger "${comparison}")
	software="EdgeR"
	path_enrichment_table="${path_output}/$(echo enrichment_table_${software}_${contrast_name} | xargs).tsv"
	test_and_run "${path_tarbase_db}" "${path_reactome_db}" "${path_enrichment_table}" "${path_reactome_interaction}" "${input_contrast}" "${software}" "${db_organism}" "${path_output}" 'EdgeR'
fi

if [[ ${selectDEAsoftware} == 'deseq' ]] || [[ ${selectDEAsoftware} == 'both' ]]; then
	path_output=$(get_output_dir deseq "${comparison}")
	software="DESeq2"
	path_enrichment_table="${path_output}/$(echo enrichment_table_${software}_${contrast_name} | xargs).tsv"
	test_and_run "${path_tarbase_db}" "${path_reactome_db}" "${path_enrichment_table}" "${path_reactome_interaction}" "${input_contrast}" "${software}" "${db_organism}" "${path_output}" 'DESeq2'
fi

if [[ ${selectDEAsoftware} == 'both' ]]; then
	path_output="$(ENV path get-dir output::deaIntOut)/${contrast_label}/"
	path_enrichment_table="${path_output}/enrichment_table_DESeq2-EdgeR_${contrast_name}.tsv"
	software='DESeq2-EdgeR'
	test_and_run "${path_tarbase_db}" "${path_reactome_db}" "${path_enrichment_table}" "${path_reactome_interaction}" "${input_contrast}" "${software}" "${db_organism}" "${path_output}" 'integrated'
fi
