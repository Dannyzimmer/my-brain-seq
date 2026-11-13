#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg deseq.PERFORMING

dea_comparison="$(echo "${comparison}" | cut -d= -f1 | tr -d '"' | xargs)"
dea_path_cond="${conditions}"
dea_path_contrast="${contrast}"
dea_path_output=$(get_output_dir deseq "${comparison}")
dea_path_pipel="${dea_path_output}pipel"
dea_path_counts="${dea_path_pipel}/all-counts_deseq_${dea_comparison}.txt"
dea_counts_source="$(ENV path get-dir output::ftqOut)/all-counts.txt"

mkdir -p "${dea_path_pipel}"
touch "${dea_path_counts}"
cat "${dea_counts_source}" | tail -n +2 > "${dea_path_counts}"

msg deseq.RUNNING

run_container r_deseq2 Rscript "${pipelineDir}/${scriptsDir}/${deSeq2Rscript}" "${dea_path_counts}" "${dea_path_cond}" "${comparison}" "${dea_path_output}" "${qvalue}" "${log2FC}"

dea_results_file="${dea_path_output}DESeq2_${dea_comparison}.tsv"
dea_demirnas_file="${dea_path_output}differentially-expressed-miRNAs_DESeq2_${dea_comparison}.tsv"

if [[ -f "${dea_results_file}" ]]; then
	register_output "deseq:${dea_comparison}_results" "${dea_results_file}" "output::dsqOut"
fi
if [[ -f "${dea_demirnas_file}" ]]; then
	register_output "deseq:${dea_comparison}_demiRNAs" "${dea_demirnas_file}" "output::dsqOut"
fi
