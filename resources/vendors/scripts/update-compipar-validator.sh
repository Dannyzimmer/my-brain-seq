#!/usr/bin/env bash
set -o nounset
set -o errexit

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/compipar-validator" >&2
    exit 1
fi

SOURCE="$1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DEST="${ROOT}/resources/vendors/compipar_validator"

if [[ ! -f "${SOURCE}/src/compipar_validator/__init__.py" ]]; then
    echo "Error: '${SOURCE}' does not look like the compipar-validator repository" >&2
    exit 1
fi

rm -rf "${DEST}"
mkdir -p "${DEST}"
cp -a "${SOURCE}/src/compipar_validator/." "${DEST}/"
find "${DEST}" -type d -name '__pycache__' -prune -exec rm -rf {} +
find "${DEST}" -type f -name '*.pyc' -delete
cp "${SOURCE}/LICENSE" "${DEST}/LICENSE"
cp "${SOURCE}/README.md" "${DEST}/README.md"

echo "Updated ${DEST}"
