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

if [[ "${containersJSON}" != "FALSE" ]]; then
	# User-provided SIFManager JSON: use it as-is.
	if [[ ! -f "${CONFIG_JSON}" ]]; then
		msg container_preparation.CONFIG_MISSING "file=${CONFIG_JSON}"
		exit 1
	fi
	msg container_preparation.USING_CONFIG "file=${CONFIG_JSON}"
	PULL_WITH_PWD="FALSE"
else
	# Copy the canonical containers JSON and resolve the SIF paths against the
	# requested download directory.
	mkdir -p "${CONTAINERS_DIR}"
	cp "${DEFAULT_JSON}" "${CONFIG_JSON}"
	SIF_MANAGER config update --new-path "${CONTAINERS_DIR}" "${CONFIG_JSON}"
	msg container_preparation.USING_CONFIG "file=${CONFIG_JSON}"
	PULL_WITH_PWD="TRUE"
fi

if [[ -v skipPullDockerImages ]]; then
	msg container_preparation.SKIP_PULL
elif [[ "${PULL_WITH_PWD}" == "TRUE" ]]; then
	SIF_MANAGER --indented batch-pull --pwd "${CONTAINERS_DIR}" "${CONFIG_JSON}"
else
	SIF_MANAGER --indented batch-pull "${CONFIG_JSON}"
fi

function save_img_to_env {
	local image_name="${1}"
	local image_path
	image_path="$(SIF_MANAGER config get-path --image-name "${image_name}" "${CONFIG_JSON}")"
	if [[ ! -f "${image_path}" ]]; then
		msg container_preparation.IMAGE_MISSING "image=${image_name}" "path=${image_path}"
		exit 1
	fi
	ENV param set "singularity::${image_name}" "${image_path}"
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
