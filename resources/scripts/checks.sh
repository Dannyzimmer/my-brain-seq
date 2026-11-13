#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER
LOAD_TESTS
source "${pipelineDir}/${scriptsDir}/functions.sh"

FAILED=0

mark_failed() {
	FAILED=1
}

msg checks.ENV_TEST
if ! test_local; then
	mark_failed
fi
if ! test_slurm; then
	mark_failed
fi

msg checks.USER_INPUT

if [[ ! -d "${fastqDir}" ]]; then
	test_msg_custom "fastq_dir" inputs.FASTQ_DIR_MISSING "directory=${fastqDir}"
	mark_failed
elif ! compgen -G "${fastqDir}/*.fastq" > /dev/null && ! compgen -G "${fastqDir}/*.fastq.gz" > /dev/null; then
	test_msg_custom "fastq_dir" inputs.FASTQ_NONE "directory=${fastqDir}"
	mark_failed
else
	test_msg_custom "fastq_dir" inputs.SUCCESS
fi

if [[ ! -f "${conditions}" ]]; then
	test_msg_custom "conditions" inputs.CONDITIONS_MISSING "file=${conditions}"
	mark_failed
else
	test_msg_custom "conditions" inputs.SUCCESS
fi

if [[ ! -f "${contrast}" ]]; then
	test_msg_custom "contrast" inputs.CONTRAST_MISSING "file=${contrast}"
	mark_failed
else
	test_msg_custom "contrast" inputs.SUCCESS
fi

if [[ ! -f "${gffFile}" ]]; then
	test_msg_custom "gff" inputs.GFF_MISSING "file=${gffFile}"
	mark_failed
else
	test_msg_custom "gff" inputs.SUCCESS
fi

if [[ -z "${genome}" && -z "${bwtIndex}" ]]; then
	test_msg_custom "reference" inputs.REFERENCE_MISSING
	mark_failed
elif [[ -n "${genome}" && ! -f "${genome}" ]]; then
	test_msg_custom "genome" inputs.GENOME_MISSING "file=${genome}"
	mark_failed
elif [[ -n "${bwtIndex}" && ! -f "${bwtIndex}.1.ebwt" && ! -f "${bwtIndex}.1.ebwtl" ]]; then
	test_msg_custom "bowtie_index" inputs.INDEX_MISSING "file=${bwtIndex}"
	mark_failed
else
	test_msg_custom "reference" inputs.SUCCESS
fi

if [[ -z "${organism}" ]]; then
	test_msg_custom "organism" inputs.ORGANISM_MISSING
	mark_failed
else
	test_msg_custom "organism" inputs.SUCCESS
fi

case "${selectDEAsoftware}" in
	deseq|edger|both)
		test_msg_custom "selectDEAsoftware" inputs.SUCCESS
		;;
	*)
		test_msg_custom "selectDEAsoftware" inputs.SELECT_DEA_INVALID "value=${selectDEAsoftware}"
		mark_failed
		;;
esac

databases_dir="$(resolve_pipeline_path "${databasesDir}")"

if [[ ! -f "${databases_dir}/${tarbaseDB}" ]]; then
	msg checks.DATABASE_MISSING "file=${databases_dir}/${tarbaseDB}"
else
	test_msg_custom "tarbase_db" inputs.SUCCESS
fi

if [[ ! -f "${databases_dir}/${reactomeDB}" ]]; then
	msg checks.DATABASE_MISSING "file=${databases_dir}/${reactomeDB}"
else
	test_msg_custom "reactome_db" inputs.SUCCESS
fi

if [[ ! -f "${databases_dir}/${reactomeInteractionsDB}" ]]; then
	msg checks.DATABASE_MISSING "file=${databases_dir}/${reactomeInteractionsDB}"
else
	test_msg_custom "reactome_interactions" inputs.SUCCESS
fi

if (( FAILED )); then
	exit 1
fi

msg checks.ALL_PASSED
