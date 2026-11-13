#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg edger.PERFORMING

er_comparison="$(echo "${comparison}" | cut -d= -f1 | tr -d '"' | xargs)"
er_path_output=$(get_output_dir edger "${comparison}")
er_path_pipel="${er_path_output}pipel"
er_path_counts="${er_path_pipel}/all-counts_edger_${er_comparison}.txt"
er_path_cond="${conditions}"
er_path_contrast="${contrast}"
er_counts_source="$(ENV path get-dir output::ftqOut)/all-counts.txt"

mkdir -p "${er_path_pipel}"
touch "${er_path_counts}"
cat "${er_counts_source}" | tail -n +2 > "${er_path_counts}"

msg edger.RUNNING

run_container r_edger Rscript "${pipelineDir}/${scriptsDir}/${edgerRscript}" "${er_path_counts}" "${er_path_cond}" "${comparison}" "${er_path_output}" "${qvalue}" "${log2FC}"

er_results_file="${er_path_output}EdgeR_${er_comparison}.tsv"
er_demirnas_file="${er_path_output}differentially-expressed-miRNAs_EdgeR_${er_comparison}.tsv"

if [[ -f "${er_results_file}" ]]; then
	register_output "edger:${er_comparison}_results" "${er_results_file}" "output::edgOut"
fi
if [[ -f "${er_demirnas_file}" ]]; then
	register_output "edger:${er_comparison}_demiRNAs" "${er_demirnas_file}" "output::edgOut"
fi
