#!/bin/bash
#SBATCH --job-name=calisto_test-01
#SBATCH --nodes=1
#SBATCH --ntasks=3
#SBATCH --cpus-per-task=10
#SBATCH --mem=50G
#SBATCH --time=0-00:20:00
#SBATCH --output=LOG_%x.log
set -e

SCRIPT_DIR="${SLURM_SUBMIT_DIR}"
TESTS_ROOT="$(dirname ${SCRIPT_DIR})"
CONFIG_JSON="${TESTS_ROOT}/tests-config.json"
PIPEL_ENTRYPOINT="$(jq -r '.pipeline_entrypoint' ${CONFIG_JSON})"

# $1 : Additional compi parameters (as a single string)
"${PIPEL_ENTRYPOINT}" run "${SCRIPT_DIR}/compi.parameters" --add-params "${1}"
