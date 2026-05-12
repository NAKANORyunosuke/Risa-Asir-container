#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
IMAGE_NAME="${RISA_ASIR_IMAGE:-risa-asir:latest}"

DOCKER_BUILDKIT=1 docker build --no-cache -t "${IMAGE_NAME}" -f "${REPO_ROOT}/dockerfile" "${REPO_ROOT}" 2>&1 | tee "${SCRIPT_DIR}/build.log"
