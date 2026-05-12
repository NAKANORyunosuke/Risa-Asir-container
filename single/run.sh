#!/bin/sh
set -eu

IMAGE_NAME="${RISA_ASIR_IMAGE:-risa-asir:latest}"
CONTAINER_NAME="risa-asir-container"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        docker start "$CONTAINER_NAME" >/dev/null
    fi
else
    docker run -dit \
        --name "$CONTAINER_NAME" \
        -v "${REPO_ROOT}:/workspace" \
        -w /workspace \
        "$IMAGE_NAME" \
        bash
fi

docker exec -it "$CONTAINER_NAME" bash
