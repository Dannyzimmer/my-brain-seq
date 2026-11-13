#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER
LOAD_TESTS
LOAD_SINGULARITY_ENV

PRIVATE_CONTAINER_DIR="${pipelineDir}/${privateContainerDir}"
DEFAULT_JSON="${PRIVATE_CONTAINER_DIR}/${privateContainersJSON}"
CONFIG_JSON="$(ENV param get containerJSON)"
CONTAINERS_DIR="$(ENV param get containersDir)"

if ! [[ -f  "${CONFIG_JSON}" ]]; then
    # Build custom `containers.json` file
    cp "${DEFAULT_JSON}" "${CONFIG_JSON}"
    # Download / check images
    SIF_MANAGER config update --new-path "${CONTAINERS_DIR}" "${CONFIG_JSON}"
fi

# Download / check images
if [[ "${containersJSON}" == "FALSE" && "${containersDir}" == "FALSE" ]]; then
    SIF_MANAGER \
        --indented batch-pull --pwd "${PRIVATE_CONTAINER_DIR}" "${CONFIG_JSON}"
else
    SIF_MANAGER --indented batch-pull "${CONFIG_JSON}"
fi

# Save vars to environment
function save_img_to_env {
    local image_name="${1}"
    ENV param set \
    "singularity::${image_name}" \
    "$(SIF_MANAGER config get-path --image-name "${image_name}" ${CONFIG_JSON})"
}

function save_all_images_to_env {
    local config_file="$1"
    while IFS= read -r image_name; do
        [[ -z "$image_name" ]] && continue
        msg common.IMG_SAVED_TO_ENV "image_name=${image_name}"
        save_img_to_env "$image_name"
    done < <(SIF_MANAGER config get-names "$config_file")
}

msg common.UPDATING_ENV_DB
save_all_images_to_env "${CONFIG_JSON}"
