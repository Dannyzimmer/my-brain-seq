#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

if [[ "${adapter}" != "NA" ]]; then
	msg cut_sequences.REMOVING
	msg cut_sequences.PROCESSING "file=${file}"

	ctd_output="$(ENV path get-dir output::ctdOut)/trimmed_${file}"
	run_container cutadapt cutadapt -m 1 -a "${adapter}" -o "${ctd_output}" "${fastqDir}/${file}"
	register_output "cutadapt:${file}" "${ctd_output}" "output::ctdOut"
else
	msg cut_sequences.SKIPPED
fi
