#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg fastqc_qc.PERFORMING
msg fastqc_qc.PROCESSING "file=${file}"

fqc_input="${fastqDir}/${file}"
fqc_output="$(ENV path get-dir output::fqcOut)/"

run_container fastqc fastqc -o "${fqc_output}" "${fqc_input}"

sample="${file%.fastq*}"
if [[ -f "${fqc_output}${sample}_fastqc.html" ]]; then
	register_output "fastqc:${sample}_html" "${fqc_output}${sample}_fastqc.html" "output::fqcOut"
fi
if [[ -f "${fqc_output}${sample}_fastqc.zip" ]]; then
	register_output "fastqc:${sample}_zip" "${fqc_output}${sample}_fastqc.zip" "output::fqcOut"
fi
