#!/usr/bin/env bash
set -e

ELECTRON_VERSION="${1:-$ELECTRON_VERSION}"
TARGET_ARCH="${2:-$TARGET_ARCH}"
DEST_DIR="${3:-/build/pkg/opt/factory-desktop}"

if [ -z "$ELECTRON_VERSION" ] || [ -z "$TARGET_ARCH" ]; then
    echo "Usage: download-electron.sh <ELECTRON_VERSION> <TARGET_ARCH> [DEST_DIR]"
    exit 1
fi

echo "[download-electron] Electron v${ELECTRON_VERSION} for ${TARGET_ARCH}"

mkdir -p "${DEST_DIR}"

ELECTRON_CACHE_DIR="/tmp/electron-cache"
rm -rf "${ELECTRON_CACHE_DIR}"
mkdir -p "${ELECTRON_CACHE_DIR}"

cd /tmp
rm -rf /tmp/electron-install
npm init -y > /dev/null 2>&1
npm install "electron@${ELECTRON_VERSION}" --prefix /tmp/electron-install 2>&1 | tail -3

ELECTRON_DIST="/tmp/electron-install/node_modules/electron/dist"

if [ ! -f "${ELECTRON_DIST}/electron" ]; then
    echo "ERROR: Electron binary not found at ${ELECTRON_DIST}/electron"
    ls -la "${ELECTRON_DIST}/" || true
    exit 1
fi

cp "${ELECTRON_DIST}/electron" "${DEST_DIR}/factory-desktop"
chmod 755 "${DEST_DIR}/factory-desktop"

for f in chrome_100_percent.pak chrome_200_percent.pak icudtl.dat resources.pak snapshot_blob.bin v8_context_snapshot.bin; do
    if [ -f "${ELECTRON_DIST}/${f}" ]; then
        cp "${ELECTRON_DIST}/${f}" "${DEST_DIR}/"
    fi
done

for f in libEGL.so libGLESv2.so libffmpeg.so libvk_swiftshader.so; do
    if [ -f "${ELECTRON_DIST}/${f}" ]; then
        cp "${ELECTRON_DIST}/${f}" "${DEST_DIR}/"
    fi
done

if [ -d "${ELECTRON_DIST}/locales" ]; then
    cp -r "${ELECTRON_DIST}/locales" "${DEST_DIR}/"
fi

echo "  Electron v${ELECTRON_VERSION} files copied to ${DEST_DIR}"
