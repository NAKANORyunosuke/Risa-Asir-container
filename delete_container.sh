#!/bin/sh
set -eu

IMAGE_NAME="risa-asir:latest"
CONTAINER_NAME="risa-asir-container"

# container が存在すれば停止・削除
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    docker rm -f "$CONTAINER_NAME"
fi

# image が存在すれば削除
if docker images --format '{{.Repository}}:{{.Tag}}' | grep -qx "$IMAGE_NAME"; then
    docker rmi "$IMAGE_NAME"
fi