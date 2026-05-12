#!/bin/sh
set -eu

IMAGE_NAME="${RISA_ASIR_IMAGE:-ghcr.io/nakanoryunosuke/risa-asir-container:latest}"

docker pull "${IMAGE_NAME}"
