#!/usr/bin/env bash
# Factory Desktop post-install script (distro-aware)

APP_VERSION="${APP_VERSION:-0.114.1}"

# Update desktop database (if available)
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
fi

# Update icon cache (if available — GNOME, Xfce, etc.)
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true
fi

# Register protocol handler (if available)
if command -v xdg-mime &>/dev/null; then
    xdg-mime default factory-desktop.desktop x-scheme-handler/factory 2>/dev/null || true
fi

echo ""
echo "Factory Desktop v${APP_VERSION} installed successfully!"
echo ""
echo "Run 'factory-desktop' from your terminal, or find Factory in your application menu."
echo "The Droid CLI is bundled at /opt/factory-desktop/resources/bin/droid"
echo "To add 'droid' CLI to your PATH, run:"
echo "  /opt/factory-desktop/resources/bin/droid --install-path"
echo ""
