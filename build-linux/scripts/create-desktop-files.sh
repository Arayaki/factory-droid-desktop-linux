#!/usr/bin/env bash
set -e

APPS_DIR="${1:-/build/pkg/usr/share/applications}"
ICONS_DIR="${2:-/build/pkg/usr/share/icons/hicolor/256x256/apps}"
BIN_LINK_DIR="${3:-/build/pkg/usr/bin}"

echo "[create-desktop-files] Creating desktop integration..."

mkdir -p "${APPS_DIR}" "${ICONS_DIR}" "${BIN_LINK_DIR}"

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

cat > "${ICONS_DIR}/factory-desktop.svg" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
  <rect width="256" height="256" rx="48" fill="#6450DC"/>
  <text x="128" y="160" text-anchor="middle" font-family="sans-serif" font-size="120" font-weight="bold" fill="white">F</text>
</svg>
SVGEOF

echo "  Desktop integration done"
