#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg build_genome_index.BUILDING
msg build_genome_index.GENOME_PATH "genome=${genome}"

genome_name="$(basename "${genome}" | cut -d '.' -f1)"

bgi_output="${workingDir}/input/genome/${genome_name}/bowtie-index_${genome_name}"
bgi_index_path="${bgi_output}/${genome_name}"

if [[ -d "${bgi_output}" ]] && [[ -n "$(ls -A "${bgi_output}")" ]]; then
	msg build_genome_index.ALREADY_EXISTS "path=${bgi_output}"
	msg build_genome_index.SKIPPING
else
	msg build_genome_index.GENOME_FILE "path=${genome}"
	msg build_genome_index.OUTPUT_PATH "path=${bgi_output}"
	msg build_genome_index.INDEX_ROOT "name=${genome}"
	msg build_genome_index.RUNNING
	run_container bowtie1 sh -c "mkdir -p '${bgi_output}' && cd '${bgi_output}' && bowtie-build -f '${genome}' '${bgi_index_path}'"
fi
