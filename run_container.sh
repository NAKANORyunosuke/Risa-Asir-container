#!/bin/sh
set -eu

IMAGE_NAME="risa-asir:latest"
CONTAINER_NAME="risa-asir-container"

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        docker start "$CONTAINER_NAME" >/dev/null
    fi
else
    docker run -dit \
        --name "$CONTAINER_NAME" \
        "$IMAGE_NAME" \
        bash
fi

docker exec -it "$CONTAINER_NAME" bash
