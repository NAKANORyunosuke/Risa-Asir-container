#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo ./setup_docker.sh"
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "This script supports apt-based distributions only."
    exit 1
fi

if [ ! -r /etc/os-release ]; then
    echo "Cannot detect OS (/etc/os-release not found)."
    exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release

DISTRO_ID="${ID:-}"
CODENAME="${VERSION_CODENAME:-}"

case "$DISTRO_ID" in
    ubuntu|debian)
        ;;
    *)
        echo "Unsupported distribution: ${DISTRO_ID:-unknown}"
        echo "Supported: ubuntu, debian"
        exit 1
        ;;
esac

if [ -z "$CODENAME" ]; then
    echo "Could not determine distribution codename."
    exit 1
fi

echo "[1/7] Installing prerequisites..."
apt-get update
apt-get install -y ca-certificates curl gnupg

echo "[2/7] Setting up Docker APT repository..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/${DISTRO_ID}/gpg" \
    | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

ARCH="$(dpkg --print-architecture)"
echo \
    "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO_ID} ${CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

echo "[3/7] Installing Docker packages..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[4/7] Enabling Docker services..."
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now containerd || true
    systemctl enable --now docker || true
else
    echo "systemctl not found; skipping service enable/start."
fi

echo "[5/7] Configuring docker group..."
TARGET_USER=""
if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
    TARGET_USER="${SUDO_USER}"
elif [ -n "${DOCKER_SETUP_USER:-}" ] && [ "${DOCKER_SETUP_USER}" != "root" ]; then
    TARGET_USER="${DOCKER_SETUP_USER}"
fi

if [ -n "$TARGET_USER" ] && id "$TARGET_USER" >/dev/null 2>&1; then
    usermod -aG docker "$TARGET_USER"
    echo "Added '${TARGET_USER}' to docker group."
    echo "Run 'newgrp docker' or re-login to apply group changes."
else
    echo "No non-root target user detected."
    echo "If needed, run: sudo usermod -aG docker <username>"
fi

echo "[6/7] Showing Docker versions..."
docker --version
docker compose version

echo "[7/7] Verifying with hello-world..."
if docker run --rm hello-world >/dev/null 2>&1; then
    echo "Docker hello-world check: OK"
else
    echo "Docker hello-world check failed."
    echo "Try: sudo systemctl status docker"
    exit 1
fi

echo "Docker setup completed."
