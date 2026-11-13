#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg venn.BUILDING_FILE

msg venn.FINDING
vp_comparison_label=$(echo "${comparison}" | cut -d'"' -f2)
vp_comparison_label_file=$(echo "${comparison}" | cut -d'"' -f4)

pipel_dir_name='pipel'
output="$(ENV path get-dir output::deaIntOut)/${vp_comparison_label}/"
output_pipel="${output}${pipel_dir_name}/"

venn_path="${output_pipel}/DEmiRNAs_${vp_comparison_label_file}_deseq-edger_venn.tsv"
venn_output="${output}"
venn_output_format="${vennFormat}"
input_contrast="${comparison}"

msg venn.BUILDING

run_container r_venn-diagram Rscript "${pipelineDir}/${scriptsDir}/${vennRscript}" "${venn_path}" "${venn_output}" "${venn_output_format}" "${input_contrast}"

venn_file="${venn_output}DESeq2-EdgeR_${vp_comparison_label_file}_results_venn.${vennFormat}"
if [[ -f "${venn_file}" ]]; then
	register_output "venn:${vp_comparison_label_file}" "${venn_file}" "output::deaIntOut"
fi
