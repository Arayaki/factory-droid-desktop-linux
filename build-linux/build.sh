#!/usr/bin/env bash
set -e

ELECTRON_VERSION="${ELECTRON_VERSION:-39.2.7}"
DROID_CLI_VERSION="${DROID_CLI_VERSION:-0.157.1}"
APP_VERSION="0.114.1"
OUTPUT_DIR="/output"
PKG_DIR="/build/pkg"
OPT_DIR="${PKG_DIR}/opt/factory-desktop"
RESOURCES_DIR="${OPT_DIR}/resources"
BIN_DIR="${RESOURCES_DIR}/bin"
APPS_DIR="${PKG_DIR}/usr/share/applications"
ICONS_DIR="${PKG_DIR}/usr/share/icons/hicolor/256x256/apps"
BIN_LINK_DIR="${PKG_DIR}/usr/bin"
ELECTRON_CACHE_DIR="/tmp/electron-cache"

echo "=== Factory Desktop Linux Build ==="
echo "Electron: v${ELECTRON_VERSION}"
echo "Droid CLI: v${DROID_CLI_VERSION}"
echo "App: v${APP_VERSION}"

rm -rf "${PKG_DIR}" "${ELECTRON_CACHE_DIR}"
mkdir -p "${OPT_DIR}" "${BIN_DIR}" "${APPS_DIR}" "${ICONS_DIR}" "${BIN_LINK_DIR}" "${OUTPUT_DIR}" "${ELECTRON_CACHE_DIR}"

# --------------------------------------------------
# 1. Install and extract Electron for Linux via npm
# --------------------------------------------------
echo "[1/5] Installing Electron v${ELECTRON_VERSION} for Linux..."

cd /tmp
npm init -y > /dev/null 2>&1
npm install "electron@${ELECTRON_VERSION}" --prefix /tmp/electron-install 2>&1 | tail -3

ELECTRON_DIST="/tmp/electron-install/node_modules/electron/dist"

if [ ! -f "${ELECTRON_DIST}/electron" ]; then
    echo "ERROR: Electron binary not found at ${ELECTRON_DIST}/electron"
    ls -la "${ELECTRON_DIST}/" || true
    exit 1
fi

cp "${ELECTRON_DIST}/electron" "${OPT_DIR}/factory-desktop"
chmod 755 "${OPT_DIR}/factory-desktop"

for f in chrome_100_percent.pak chrome_200_percent.pak icudtl.dat resources.pak snapshot_blob.bin v8_context_snapshot.bin; do
    if [ -f "${ELECTRON_DIST}/${f}" ]; then
        cp "${ELECTRON_DIST}/${f}" "${OPT_DIR}/"
    fi
done

for f in libEGL.so libGLESv2.so libffmpeg.so libvk_swiftshader.so; do
    if [ -f "${ELECTRON_DIST}/${f}" ]; then
        cp "${ELECTRON_DIST}/${f}" "${OPT_DIR}/"
    fi
done

if [ -d "${ELECTRON_DIST}/locales" ]; then
    cp -r "${ELECTRON_DIST}/locales" "${OPT_DIR}/"
fi

echo "  Electron v${ELECTRON_VERSION} files copied"

# --------------------------------------------------
# 2. Download Droid CLI for Linux
# --------------------------------------------------
echo "[2/5] Downloading Droid CLI v${DROID_CLI_VERSION}..."

DROID_URL="https://downloads.factory.ai/factory-cli/releases/${DROID_CLI_VERSION}/linux/x64/droid"
SHA_URL="${DROID_URL}.sha256"

curl -fsSL -o "${BIN_DIR}/droid" "${DROID_URL}"
chmod 755 "${BIN_DIR}/droid"

curl -fsSL -o /tmp/droid.sha256 "${SHA_URL}"
EXPECTED_SHA=$(awk '{print $1}' /tmp/droid.sha256)
ACTUAL_SHA=$(sha256sum "${BIN_DIR}/droid" | awk '{print $1}')

if [ "${EXPECTED_SHA}" != "${ACTUAL_SHA}" ]; then
    echo "  WARNING: Checksum mismatch!"
    echo "  Expected: ${EXPECTED_SHA}"
    echo "  Got:      ${ACTUAL_SHA}"
else
    echo "  Checksum verified OK"
fi

echo "  Droid CLI v${DROID_CLI_VERSION} installed"

# --------------------------------------------------
# 3. Copy app.asar from build context
# --------------------------------------------------
echo "[3/5] Installing app.asar..."

ASAR_SRC="/build/input/app.asar"
if [ -f "${ASAR_SRC}" ]; then
    cp "${ASAR_SRC}" "${RESOURCES_DIR}/app.asar"
    echo "  app.asar installed (size: $(du -h ${ASAR_SRC} | cut -f1))"
else
    echo "  ERROR: app.asar not found at ${ASAR_SRC}"
    exit 1
fi

# --------------------------------------------------
# 4. Create desktop integration
# --------------------------------------------------
echo "[4/5] Creating desktop integration..."

cat > "${APPS_DIR}/factory-desktop.desktop" << 'DESKTOPEOF'
[Desktop Entry]
Name=Factory
Comment=AI Software Engineering Agent
GenericName=AI Development Agent
Exec=/opt/factory-desktop/factory-desktop %U
Icon=factory-desktop
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=factory-desktop
MimeType=x-scheme-handler/factory;
Keywords=AI;Development;Coding;Agent;Factory;Droid;
DESKTOPEOF

cat > "${BIN_LINK_DIR}/factory-desktop" << 'LAUNCHEREOF'
#!/usr/bin/env bash
exec /opt/factory-desktop/factory-desktop "$@"
LAUNCHEREOF
chmod 755 "${BIN_LINK_DIR}/factory-desktop"

# Create PNG icon using Python
python3 -c "
import struct, zlib

def create_png(width, height, r, g, b):
    def chunk(ct, data):
        c = ct + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    h = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))
    raw = b''
    for y in range(height):
        raw += b'\x00'
        for x in range(width):
            raw += bytes([r, g, b])
    return h + ihdr + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')

png = create_png(256, 256, 100, 80, 220)
with open('${ICONS_DIR}/factory-desktop.png', 'wb') as f:
    f.write(png)
"

# Generate SVG icon for better scaling
cat > "${ICONS_DIR}/factory-desktop.svg" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
  <rect width="256" height="256" rx="48" fill="#6450DC"/>
  <text x="128" y="160" text-anchor="middle" font-family="sans-serif" font-size="120" font-weight="bold" fill="white">F</text>
</svg>
SVGEOF

echo "  Desktop integration done"

# --------------------------------------------------
# 5. Build RPM
# --------------------------------------------------
echo "[5/5] Building RPM with fpm..."

cd /build

fpm \
    -s dir \
    -t rpm \
    -n factory-desktop \
    -v "${APP_VERSION}" \
    --iteration 1 \
    --architecture x86_64 \
    --description "Factory Droid Desktop - AI Software Engineering Agent" \
    --url "https://factory.ai" \
    --maintainer "The San Francisco AI Factory, Inc. <engineering@factory.ai>" \
    --vendor "Factory AI" \
    --license "Proprietary" \
    --depends "xdg-utils" \
    --depends "libstdc++" \
    --depends "libX11" \
    --depends "libXcomposite" \
    --depends "libXdamage" \
    --depends "libXext" \
    --depends "libXfixes" \
    --depends "libXrandr" \
    --depends "libxcb" \
    --depends "libxkbcommon" \
    --depends "libdrm" \
    --depends "mesa-libgbm" \
    --depends "nss" \
    --depends "nspr" \
    --depends "alsa-lib" \
    --depends "atk" \
    --depends "at-spi2-atk" \
    --depends "cups-libs" \
    --depends "gtk3" \
    --depends "pango" \
    --depends "cairo" \
    --depends "dbus-libs" \
    --depends "expat" \
    --depends "gdk-pixbuf2" \
    --depends "glibc >= 2.28" \
    --depends "glib2" \
    --depends "libuuid" \
    --depends "libnotify" \
    --depends "libsecret" \
    --rpm-os linux \
    --after-install /build/postinst.sh \
    -C "${PKG_DIR}" \
    --package "${OUTPUT_DIR}/factory-desktop-${APP_VERSION}-1.fc43.x86_64.rpm" \
    opt usr

echo ""
echo "=== Build Complete ==="
ls -lh "${OUTPUT_DIR}/"

rpm -qpi "${OUTPUT_DIR}/"*.rpm 2>/dev/null || true
