#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER
LOAD_TESTS

# Environment tests
msg checks.ENV_TEST
test_local
test_slurm

# User data
# checks the parameters in compi.parameters
# msg checks.USER_INPUT

# Test Singularity images
# msg checks.SIF_IMAGES

# test_singularity_image \
#     "$(GET_SIF seqkit)" \
#     seqkit \
#     seqkit --help

# msg checks.ALL_PASSED