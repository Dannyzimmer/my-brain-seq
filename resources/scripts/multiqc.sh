#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg multiqc.STARTING

results_path="${workingDir}/${outDir}/"
output_dir="$(ENV path get-dir output::mqcOut)/"

run_container multiqc multiqc "${results_path}" --outdir "${output_dir}"

report_file="${output_dir}multiqc_report.html"
if [[ -f "${report_file}" ]]; then
	register_output "multiqc:report" "${report_file}" "output::mqcOut"
fi

msg multiqc.DONE
