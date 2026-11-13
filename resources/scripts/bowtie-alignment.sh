#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg bowtie_alignment.PERFORMING

# Choose the Bowtie index path depending on whether the user provided a
# pre-built index or whether it was built by the build-genome-index task.
if [[ -n "${genome}" ]]; then
	genome_name="$(basename "${genome}" | cut -d '.' -f1)"
	bw_index_path="${workingDir}/input/genome/${genome_name}/bowtie-index_${genome_name}"
	bwtIndex="${bw_index_path}/${genome_name}"
elif [[ -n "${bwtIndex}" ]]; then
	bw_index_path="$(dirname "${bwtIndex}")"
else
	msg bowtie_alignment.ERROR_NO_INDEX
fi

if [[ "${adapter}" != "NA" ]]; then
	bw_fastq="${workingDir}/${outDir}/${ctdOut}/${file}"
else
	bw_fastq="${fastqDir}/${file}"
fi

bw_fastq=$(echo "${bw_fastq}" | tr -s '/')
bw_output="$(ENV path get-dir output::bwtOut)/${file}.sam"
bw_output=$(echo "${bw_output}" | tr -s '/')

msg bowtie_alignment.INDEX "index=${bwtIndex}"

if [[ -f "${bw_output}" ]]; then
	msg bowtie_alignment.SAM_EXISTS "file=${file}.sam"
	rm -f "${bw_output}"
fi

msg bowtie_alignment.ALIGNING "file=${file}.sam"

run_container bowtie1 bowtie -S ${bwt_additional_args} "${bwtIndex}" "${bw_fastq}" "${bw_output}"

if [[ -f "${bw_output}" ]]; then
	register_output "bowtie:${file}" "${bw_output}" "output::bwtOut"
fi
