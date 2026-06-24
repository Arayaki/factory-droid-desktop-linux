#!/usr/bin/env bash
set -e

ASAR_SRC="${1:-/build/input/app.asar}"
DEST_DIR="${2:-/build/pkg/opt/factory-desktop/resources}"

echo "[install-app-asar] Installing app.asar..."

if [ ! -f "${ASAR_SRC}" ]; then
    echo "  ERROR: app.asar not found at ${ASAR_SRC}"
    exit 1
fi

mkdir -p "${DEST_DIR}"
cp "${ASAR_SRC}" "${DEST_DIR}/app.asar"
echo "  app.asar installed (size: $(du -h "${ASAR_SRC}" | cut -f1))"
