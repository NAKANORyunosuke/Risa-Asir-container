#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/../.." && pwd)

RISA_ASIR_IMAGE="${RISA_ASIR_IMAGE:-ghcr.io/nakanoryunosuke/risa-asir-container:latest}" \
    "${REPO_ROOT}/single/run.sh"
