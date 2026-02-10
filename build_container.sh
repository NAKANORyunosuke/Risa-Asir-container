#!/bin/sh
set -eu

DOCKER_BUILDKIT=1 docker build --no-cache -t risa-asir . 2>&1 | tee build.log