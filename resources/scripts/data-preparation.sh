#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/functions.sh"

msg data_preparation.PREPARING

db_dir="$(resolve_pipeline_path "${databasesDir}")"
mkdir -p "${db_dir}"

download_and_decompress() {
	# $1 : output file name
	# $2 : download URL
	local output="${db_dir}/$1"
	local url="$2"
	if [[ -s "${output}" ]]; then
		msg data_preparation.ALREADY_EXISTS "file=${output}"
		return 0
	fi
	msg data_preparation.DOWNLOADING "file=${output}" "url=${url}"
	local tmp
	tmp="$(mktemp)"
	curl -L --fail --retry 3 --output "${tmp}" "${url}"
	gunzip -S .zip -c "${tmp}" > "${output}"
	rm -f "${tmp}"
}

download_plain() {
	# $1 : output file name
	# $2 : download URL
	local output="${db_dir}/$1"
	local url="$2"
	if [[ -s "${output}" ]]; then
		msg data_preparation.ALREADY_EXISTS "file=${output}"
		return 0
	fi
	msg data_preparation.DOWNLOADING "file=${output}" "url=${url}"
	curl -L --fail --retry 3 --output "${output}" "${url}"
}

download_and_decompress "${tarbaseDB}" "http://static.sing-group.org/software/myBrainSeq/docker/TarBase_v8_download.zip"
download_and_decompress "${reactomeDB}" "http://static.sing-group.org/software/myBrainSeq/docker/Ensembl2Reactome.zip"
download_plain "${reactomeInteractionsDB}" "http://static.sing-group.org/software/myBrainSeq/docker/reactome.all_species.interactions.tab-delimited.txt"

msg data_preparation.DONE
