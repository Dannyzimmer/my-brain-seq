#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg feature_counts.PERFORMING

bam_input="$(ENV path get-dir output::bwtOut)/"
bam_input=$(echo "${bam_input}" | tr -s '/')

path_output="$(ENV path get-dir output::ftqOut)/"
path_output=$(echo "${path_output}" | tr -s '/')

run_container feature-counts sh -c "featureCounts -F GTF -t '${gffFeature}' -g '${gffAttribute}' -a '${gffFile}' ${ft_additional_args} -o '${path_output}all-counts.txt' '${bam_input}'*.bam"

if [[ -f "${path_output}all-counts.txt" ]]; then
	register_output "featurecounts:all_counts" "${path_output}all-counts.txt" "output::ftqOut"
fi
if [[ -f "${path_output}all-counts.txt.summary" ]]; then
	register_output "featurecounts:all_counts_summary" "${path_output}all-counts.txt.summary" "output::ftqOut"
fi
