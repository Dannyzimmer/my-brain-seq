#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg bam_stats.ANALYZING

bam_input="$(ENV path get-dir output::bwtOut)/${bamFile}"
bs_output="$(ENV path get-dir output::bamstOut)/$(echo "${bamFile}" | cut -d'.' -f1)"
bs_stats_file="${bs_output}/${bamFile}.stats"
bs_plot_names="${bs_output}/${bamFile}_PLOT"

if [[ -d "${bs_output}" ]]; then
	msg bam_stats.SKIPPING "path=${bs_output}"
	exit 0
fi

mkdir "${bs_output}"

run_container samtools_bcftools sh -c "samtools stats ${bam_input} > ${bs_stats_file}"

run_container samtools_bcftools sh -c "plot-bamstats -p ${bs_plot_names} ${bs_stats_file}"

if [[ -f "${bs_stats_file}" ]]; then
	register_output "bamstats:${bamFile}_stats" "${bs_stats_file}" "output::bamstOut"
fi
