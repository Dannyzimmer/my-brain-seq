#!/bin/bash
################################################################################
#
#       REQUIRES THE DIRECTORIES TO BE LOADED IN environment.db
#
################################################################################

set -o nounset
set -o errexit
source "${environment}"
LOAD_PRINTER

msg initialization.BUILD_DIRS

build_dir () {
	local dir_key=$1   # Output dir key in the environment database.
	dirpath="$(ENV path get-dir $dir_key)"
	dir_name="$(basename ${dirpath})"
	echo ""
	msg initialization.DIR_CREATION "dir_name=$dir_name"
	if [ ! -d "${dirpath}" ]; then
		mkdir -p "${dirpath}"
	else
		msg initialization.DIR_EXISTS "dir_name=$dir_name"
		msg initialization.RM_DIR "dirpath=$dirpath"
		rm -Rf "${dirpath}"
		msg initialization.DIR_CREATION "dir_name=$dir_name"
		mkdir -p "${dirpath}"
	fi
}

################################################################################
# DIRECTORY CREATION
################################################################################

ENV search dirs --show_keys "output:%" \
  | cut -f1 \
  | while read -r dir; do
      build_dir "$dir"
    done

echo ""