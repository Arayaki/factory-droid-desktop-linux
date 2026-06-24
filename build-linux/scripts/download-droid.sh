#!/usr/bin/env bash
set -e

DROID_CLI_VERSION="${1:-$DROID_CLI_VERSION}"
TARGET_ARCH="${2:-$TARGET_ARCH}"
DEST_DIR="${3:-/build/pkg/opt/factory-desktop/resources/bin}"

if [ -z "$DROID_CLI_VERSION" ] || [ -z "$TARGET_ARCH" ]; then
    echo "Usage: download-droid.sh <DROID_CLI_VERSION> <TARGET_ARCH> [DEST_DIR]"
    exit 1
fi

# Map architecture to download URL suffix
case "${TARGET_ARCH}" in
    x86_64|amd64)
        ARCH="x64"
        ARCH_SUFFIX=""
        ;;
    arm64|aarch64)
        ARCH="arm64"
        ARCH_SUFFIX=""
        ;;
    *)
        echo "ERROR: Unsupported architecture: ${TARGET_ARCH}"
        exit 1
        ;;
esac

echo "[download-droid] Droid CLI v${DROID_CLI_VERSION} for linux-${ARCH}"

DROID_URL="https://downloads.factory.ai/factory-cli/releases/${DROID_CLI_VERSION}/linux/${ARCH}/droid"
SHA_URL="${DROID_URL}.sha256"

mkdir -p "${DEST_DIR}"

curl -fsSL -o "${DEST_DIR}/droid" "${DROID_URL}"
chmod 755 "${DEST_DIR}/droid"

curl -fsSL -o /tmp/droid.sha256 "${SHA_URL}"
EXPECTED_SHA=$(awk '{print $1}' /tmp/droid.sha256)
ACTUAL_SHA=$(sha256sum "${DEST_DIR}/droid" | awk '{print $1}')

if [ "${EXPECTED_SHA}" != "${ACTUAL_SHA}" ]; then
    echo "  WARNING: Checksum mismatch!"
    echo "  Expected: ${EXPECTED_SHA}"
    echo "  Got:      ${ACTUAL_SHA}"
else
    echo "  Checksum verified OK"
fi

echo "  Droid CLI v${DROID_CLI_VERSION} installed"
