#!/usr/bin/env bash
set -e

# ============================================================
# Factory Desktop Linux Build — Multi-Distro
# ============================================================
# Environment variables:
#   PACKAGE_TYPE     : rpm | deb | pacman | appimage  (default: rpm)
#   TARGET_ARCH      : x86_64 | arm64                 (default: x86_64)
#   ELECTRON_VERSION : semver                          (default: 39.2.7)
#   DROID_CLI_VERSION: semver                          (default: 0.157.1)
#   APP_VERSION      : semver                          (default: 0.114.1)
# ============================================================

ELECTRON_VERSION="${ELECTRON_VERSION:-39.2.7}"
DROID_CLI_VERSION="${DROID_CLI_VERSION:-0.157.1}"
APP_VERSION="${APP_VERSION:-0.114.1}"
PACKAGE_TYPE="${PACKAGE_TYPE:-rpm}"
TARGET_ARCH="${TARGET_ARCH:-x86_64}"

OUTPUT_DIR="/output"
PKG_DIR="/build/pkg"
SCRIPTS_DIR="/build/scripts"
DEPS_DIR="/build/deps"

OPT_DIR="${PKG_DIR}/opt/factory-desktop"

echo "=== Factory Desktop Linux Build ==="
echo "Package:    ${PACKAGE_TYPE}"
echo "Arch:       ${TARGET_ARCH}"
echo "Electron:   v${ELECTRON_VERSION}"
echo "Droid CLI:  v${DROID_CLI_VERSION}"
echo "App:        v${APP_VERSION}"

rm -rf "${PKG_DIR}"
mkdir -p "${PKG_DIR}" "${OUTPUT_DIR}"

# --------------------------------------------------
# 1. Download Electron
# --------------------------------------------------
echo "[1/5] Downloading Electron..."
"${SCRIPTS_DIR}/download-electron.sh" "${ELECTRON_VERSION}" "${TARGET_ARCH}" "${OPT_DIR}"

# --------------------------------------------------
# 2. Download Droid CLI
# --------------------------------------------------
echo "[2/5] Downloading Droid CLI..."
"${SCRIPTS_DIR}/download-droid.sh" "${DROID_CLI_VERSION}" "${TARGET_ARCH}" "${OPT_DIR}/resources/bin"

# --------------------------------------------------
# 3. Install app.asar
# --------------------------------------------------
echo "[3/5] Installing app.asar..."
"${SCRIPTS_DIR}/install-app-asar.sh" "/build/input/app.asar" "${OPT_DIR}/resources"

# --------------------------------------------------
# 4. Desktop integration
# --------------------------------------------------
echo "[4/5] Creating desktop integration..."
"${SCRIPTS_DIR}/create-desktop-files.sh"

# --------------------------------------------------
# 5. Package
# --------------------------------------------------
echo "[5/5] Building ${PACKAGE_TYPE} package..."

# Map architecture for fpm naming
case "${TARGET_ARCH}" in
    x86_64) FPM_ARCH="x86_64" ; DEB_ARCH="amd64" ;;
    arm64)  FPM_ARCH="aarch64" ; DEB_ARCH="arm64" ;;
    *) echo "ERROR: Unsupported architecture: ${TARGET_ARCH}"; exit 1 ;;
esac

cd /build

# Common fpm arguments (shared by rpm, deb, pacman)
fpm_common() {
    echo -n \
        -s dir \
        -n factory-desktop \
        -v "${APP_VERSION}" \
        --iteration 1 \
        --description "Factory Droid Desktop - AI Software Engineering Agent" \
        --url "https://factory.ai" \
        --maintainer "The San Francisco AI Factory, Inc. <engineering@factory.ai>" \
        --vendor "Factory AI" \
        --license "Proprietary" \
        -C "${PKG_DIR}" \
        opt usr
}

# Read dependencies from deps file, convert to --depends args
read_deps() {
    local deps_file="$1"
    local args=""
    if [ -f "${deps_file}" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            line=$(echo "$line" | sed 's/#.*//' | xargs)
            [ -z "$line" ] && continue
            args="${args} --depends \"${line}\""
        done < "${deps_file}"
    fi
    echo "$args"
}

# Build output filename
output_name() {
    case "${PACKAGE_TYPE}" in
        rpm)
            echo "${OUTPUT_DIR}/factory-desktop-${APP_VERSION}-1.${TARGET_ARCH}.rpm"
            ;;
        deb)
            echo "${OUTPUT_DIR}/factory-desktop_${APP_VERSION}-1_${DEB_ARCH}.deb"
            ;;
        pacman)
            echo "${OUTPUT_DIR}/factory-desktop-${APP_VERSION}-1-${TARGET_ARCH}.pkg.tar.zst"
            ;;
        appimage)
            echo "${OUTPUT_DIR}/Factory-Desktop-${APP_VERSION}-${TARGET_ARCH}.AppImage"
            ;;
    esac
}

OUTPUT_FILE=$(output_name)

case "${PACKAGE_TYPE}" in
    rpm)
        DEPS_ARGS=$(read_deps "${DEPS_DIR}/fedora.txt")
        eval fpm \
            $(fpm_common) \
            -t rpm \
            --architecture "${FPM_ARCH}" \
            --rpm-os linux \
            --after-install /build/postinst.sh \
            ${DEPS_ARGS} \
            --package "${OUTPUT_FILE}"
        ;;
    deb)
        DEPS_ARGS=$(read_deps "${DEPS_DIR}/debian.txt")
        eval fpm \
            $(fpm_common) \
            -t deb \
            --architecture "${DEB_ARCH}" \
            --after-install /build/postinst.sh \
            ${DEPS_ARGS} \
            --package "${OUTPUT_FILE}"
        ;;
    pacman)
        DEPS_ARGS=$(read_deps "${DEPS_DIR}/arch.txt")
        eval fpm \
            $(fpm_common) \
            -t pacman \
            --architecture "${FPM_ARCH}" \
            --after-install /build/postinst.sh \
            ${DEPS_ARGS} \
            --package "${OUTPUT_FILE}"
        ;;
    appimage)
        echo "  Building AppImage..."

        APPDIR="/build/AppDir"
        rm -rf "${APPDIR}"
        mkdir -p "${APPDIR}"

        # Copy entire PKG_DIR tree into AppDir
        cp -a "${PKG_DIR}"/. "${APPDIR}/"

        # --------------------------------------------------
        # Create AppRun entry point
        # --------------------------------------------------
        cat > "${APPDIR}/AppRun" << 'APPRUNEOF'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "$0")")"
exec "${HERE}/opt/factory-desktop/factory-desktop" "$@"
APPRUNEOF
        chmod +x "${APPDIR}/AppRun"

        # --------------------------------------------------
        # Copy .desktop file and icon to AppDir root
        # --------------------------------------------------
        cp "${PKG_DIR}/usr/share/applications/factory-desktop.desktop" "${APPDIR}/"
        cp "${PKG_DIR}/usr/share/icons/hicolor/256x256/apps/factory-desktop.png" "${APPDIR}/"

        # --------------------------------------------------
        # Bundle dependencies with linuxdeploy
        # --------------------------------------------------
        if command -v linuxdeploy &>/dev/null; then
            echo "  Running linuxdeploy..."
            linuxdeploy \
                --appdir "${APPDIR}" \
                --desktop-file "${APPDIR}/factory-desktop.desktop" \
                --icon-file "${APPDIR}/factory-desktop.png" \
                2>&1 | tail -5
        else
            echo "  WARNING: linuxdeploy not found, skipping library bundling"
        fi

        # --------------------------------------------------
        # Create AppImage with appimagetool
        # --------------------------------------------------
        if command -v appimagetool &>/dev/null; then
            echo "  Running appimagetool..."
            ARCH="${TARGET_ARCH}" appimagetool "${APPDIR}" "${OUTPUT_FILE}" 2>&1 | tail -5
        else
            echo "  WARNING: appimagetool not found"
            echo "  AppDir ready at ${APPDIR} — package manually with:"
            echo "    appimagetool ${APPDIR} ${OUTPUT_FILE}"
        fi
        ;;
    *)
        echo "ERROR: Unsupported PACKAGE_TYPE: ${PACKAGE_TYPE}"
        echo "  Valid: rpm, deb, pacman, appimage"
        exit 1
        ;;
esac

echo ""
echo "=== Build Complete ==="
ls -lh "${OUTPUT_DIR}/"
