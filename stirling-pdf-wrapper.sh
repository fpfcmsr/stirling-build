#!/bin/bash
# Wrapper script for Stirling PDF Desktop (Flatpak)
# Sets up environment variables for the bundled JRE, LibreOffice,
# Tesseract, and Python dependencies before launching the Tauri app.

set -euo pipefail

# --- Java / JRE ---
# The Tauri app bundles a JLink JRE; if present, prefer it.
# Otherwise fall back to the Flatpak-installed OpenJDK 21.
BUNDLED_JRE="$(dirname "$(readlink -f "$0")")/../lib/stirling-pdf/jre"
if [ -d "$BUNDLED_JRE" ]; then
    export JAVA_HOME="$BUNDLED_JRE"
else
    export JAVA_HOME="/app/jre"
fi
export PATH="$JAVA_HOME/bin:$PATH"

# --- Tesseract OCR ---
export TESSDATA_PREFIX="/app/share/tessdata"

# --- LibreOffice ---
export PATH="/app/lib/libreoffice/program:$PATH"

# --- Python (for unoserver, opencv, WeasyPrint) ---
# LibreOffice's uno.py lives under its program directory
export PYTHONPATH="/app/lib/libreoffice/program:/app/lib/python3/dist-packages:${PYTHONPATH:-}"
export PATH="/app/bin:$PATH"

# --- Stirling PDF config directories ---
# Flatpak provides XDG directories; Stirling PDF uses ~/.config/Stirling-PDF
export STIRLING_PDF_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Stirling-PDF"
export STIRLING_PDF_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/Stirling-PDF"
mkdir -p "$STIRLING_PDF_CONFIG_DIR" "$STIRLING_PDF_DATA_DIR"

# --- D-Bus session bus (for LibreOffice) ---
DBUS_TMP_DIR="${XDG_RUNTIME_DIR:-/tmp}/libreoffice-dbus"
mkdir -p "$DBUS_TMP_DIR" 2>/dev/null || true
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$DBUS_TMP_DIR}"

# --- Launch unoserver in the background (for document conversions) ---
if command -v unoserver >/dev/null 2>&1; then
    unoserver --port 2003 --interface 127.0.0.1 &
    UNOSERVER_PID=$!
    trap "kill $UNOSERVER_PID 2>/dev/null || true" EXIT
fi

# --- WebKitGTK / GPU workarounds ---
# Disable DMA-BUF renderer to avoid GPU driver issues in sandbox
export WEBKIT_DISABLE_DMABUF_RENDERER=1
# Use software rendering if GPU is not available
if ! test -d /dev/dri; then
    export LIBGL_ALWAYS_SOFTWARE=1
fi

# --- Launch the Stirling PDF Tauri binary ---
exec /app/bin/stirling-pdf "$@"
