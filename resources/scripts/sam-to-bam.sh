#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg sam_to_bam.CREATING

bam_output="$(ENV path get-dir output::bwtOut)/"
bam_output="$(echo "${bam_output}" | tr -s '/')"

filebam=$(echo "${file}" | sed 's/\.sam//')
filebam=$(echo "${filebam}" | tr -s '/')

if [[ -f "${bam_output}/${filebam}.bam" ]]; then
	msg sam_to_bam.BAM_EXISTS "file=${filebam}.bam"
	rm -f "${bam_output}/${filebam}.bam"
	rm -f "${bam_output}/${filebam}.bam.bai"
fi

msg sam_to_bam.CONVERTING "file=${filebam}.sam"

run_container samtools_bcftools sh -c "samtools sort \"${bam_output}${file}\" > \"${bam_output}${filebam}.bam\" && samtools index \"${bam_output}${filebam}.bam\""

if [[ -f "${bam_output}${filebam}.bam" ]]; then
	register_output "samtools:${filebam}_bam" "${bam_output}${filebam}.bam" "output::bwtOut"
fi
if [[ -f "${bam_output}${filebam}.bam.bai" ]]; then
	register_output "samtools:${filebam}_bai" "${bam_output}${filebam}.bam.bai" "output::bwtOut"
fi

if [ ! -v samtools_keep_sam_files ]; then
	rm -f "${bam_output}/${file}"
fi
