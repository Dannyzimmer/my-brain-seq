#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"

ENV_JSON="${pipelineDir}/${privateEnvironmentJSON}"
INSTALLATION_PATH="${pipelineDir}/${privateContainerDir}/"

# Load the environment from the JSON
ENV reset
ENV json load --json-file "${ENV_JSON}"

# Add Slurm availability
if which sinfo >/dev/null 2>&1; then
    ENV param set "slurm_available" "true"
else
    ENV param set "slurm_available" "false"
fi

# Add the path to containersJSON
if [[ "${containersJSON}" == "FALSE" ]]; then
    if [[ "${containersDir}" != "FALSE" ]]; then
        # Custom location
        ENV param set "containerJSON" "${containersDir}/containers.json"
        ENV param set "containersDir" "${containersDir}"
    else
        # Default location inside the working directory
        ENV param set "containerJSON" "${workingDir}/containers/containers.json"
        ENV param set "containersDir" "${workingDir}/containers"
    fi
else
    # User JSON file
    ENV param set "containerJSON" "${containersJSON}"
    ENV param set "containersDir" "${privateContainerDir}"
fi

# Add the binaries in vendors/bin under `bin:` tag
VENDORS_BIN_PATH="$(ENV path get-dir bin)"
for f in "$VENDORS_BIN_PATH"/*; do
  [[ -f "$f" ]] || continue
  n="${f##*/}"
  n="${n%.*}"
  ENV path add-file "bin:$n" "$f" "bin"
done

LOAD_PRINTER
msg env_preparation.VAR_LOADED
