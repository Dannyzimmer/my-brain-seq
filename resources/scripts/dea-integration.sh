#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg dea_integration.INTEGRATING

msg dea_integration.FINDING
vp_comparison_label=$(echo "${comparison}" | cut -d'=' -f1 | tr -d '\"' | xargs)
contrast_name=$(echo "${comparison}" | cut -d'"' -f4)

pipel_dir_name='pipel'

path_deseq="$(ENV path get-dir output::dsqOut)/${vp_comparison_label}/DESeq2_${vp_comparison_label}.tsv"
path_edger="$(ENV path get-dir output::edgOut)/${vp_comparison_label}/EdgeR_${vp_comparison_label}.tsv"
input_contrast="${comparison}"
path_output="$(ENV path get-dir output::deaIntOut)/${vp_comparison_label}"
path_output_pipel="${path_output}/${pipel_dir_name}"

mkdir -p "${path_output_pipel}"

msg dea_integration.DESEQ_FILE "file=${path_deseq}"
msg dea_integration.EDGER_FILE "file=${path_edger}"

msg dea_integration.RUNNING

run_container r_data-analysis Rscript "${pipelineDir}/${scriptsDir}/${deaIntRscript}" "${path_deseq}" "${path_edger}" "${input_contrast}" "${path_output}" "${path_output_pipel}" "${qvalue}" "${log2FC}"

integrated_file="${path_output}/DEmiRNAs_${contrast_name}_deseq-edger_integrated.tsv"
integrated_full_file="${path_output_pipel}/DEmiRNAs_${contrast_name}_deseq-edger_integrated_full.tsv"
demirnas_file="${path_output}/differentially-expressed-miRNAs_${contrast_name}_deseq-edger_integrated.tsv"
coincidences_file="${path_output_pipel}/DEmiRNAs_${contrast_name}_deseq-edger_coincidences.tsv"
venn_file="${path_output_pipel}/DEmiRNAs_${contrast_name}_deseq-edger_venn.tsv"

for path in "${integrated_file}" "${integrated_full_file}" "${demirnas_file}" "${coincidences_file}" "${venn_file}"; do
	if [[ -f "${path}" ]]; then
		file_key=$(basename "${path}" | tr -c '[:alnum:]_.-' '_')
		register_output "deaintegration:${file_key}" "${path}" "output::deaIntOut"
	fi
done

msg dea_integration.DONE
