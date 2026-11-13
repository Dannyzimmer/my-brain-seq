#!/bin/bash
set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

msg remove_containers.STARTING

CONFIG_JSON="$(ENV param get containerJSON)"

if [[ ! -f "${CONFIG_JSON}" ]]; then
	msg container_preparation.CONFIG_MISSING "file=${CONFIG_JSON}"
	exit 1
fi

while IFS= read -r image_name; do
	[[ -z "${image_name}" ]] && continue
	image_path="$(SIF_MANAGER config get-path --image-name "${image_name}" "${CONFIG_JSON}")"
	if [[ -f "${image_path}" ]]; then
		msg remove_containers.REMOVING "image=${image_name}" "path=${image_path}"
		rm -f "${image_path}"
	fi
done < <(SIF_MANAGER config get-names "${CONFIG_JSON}")

msg remove_containers.DONE
