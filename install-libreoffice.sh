#!/bin/bash
# install-libreoffice.sh
# Helper script to extract LibreOffice from the TDF .tar.gz archive
# which contains nested .deb packages.
#
# Usage (inside flatpak-builder build-commands):
#   bash install-libreoffice.sh LibreOffice_*.tar.gz /app
#
# The TDF archive structure is:
#   LibreOffice_X.Y.Z_Linux_x86-64_deb/
#     DEBS/
#       libobasis*-core_*.deb
#       libobasis*-writer_*.deb
#       libobasis*-calc_*.deb
#       libobasis*-impress_*.deb
#       libobasis*-common_*.deb
#       ...

set -euo pipefail

ARCHIVE="$1"
PREFIX="${2:-/app}"

WORKDIR="$(mktemp -d)"
trap "rm -rf '$WORKDIR'" EXIT

echo "==> Extracting LibreOffice archive..."
tar xzf "$ARCHIVE" -C "$WORKDIR" --strip-components=1

DEBS_DIR="$WORKDIR/DEBS"
if [ ! -d "$DEBS_DIR" ]; then
    echo "ERROR: DEBS directory not found in archive"
    exit 1
fi

echo "==> Extracting .deb packages..."
for deb in "$DEBS_DIR"/*.deb; do
    echo "  -> $(basename "$deb")"
    # Extract data from each .deb
    EXTRACT_DIR="$(mktemp -d)"
    ar x "$deb" --output="$EXTRACT_DIR"

    # Find and extract the data archive (data.tar.xz, data.tar.gz, etc.)
    DATA_TAR=$(find "$EXTRACT_DIR" -name 'data.tar.*' -print -quit)
    if [ -n "$DATA_TAR" ]; then
        tar xf "$DATA_TAR" -C "$EXTRACT_DIR/root" 2>/dev/null || {
            mkdir -p "$EXTRACT_DIR/root"
            tar xf "$DATA_TAR" -C "$EXTRACT_DIR/root"
        }

        # Copy contents to the prefix, relocating /opt/libreoffice -> /app/lib/libreoffice
        if [ -d "$EXTRACT_DIR/root/opt" ]; then
            find "$EXTRACT_DIR/root/opt" -mindepth 1 -maxdepth 1 -type d | while read -r lodir; do
                mkdir -p "$PREFIX/lib/libreoffice"
                cp -a "$lodir"/* "$PREFIX/lib/libreoffice/" 2>/dev/null || true
            done
        fi

        # Also copy /usr contents (desktop files, icons, mime types)
        if [ -d "$EXTRACT_DIR/root/usr" ]; then
            cp -a "$EXTRACT_DIR/root/usr"/* "$PREFIX/" 2>/dev/null || true
        fi
    fi

    rm -rf "$EXTRACT_DIR"
done

# Create symlinks in /app/bin
mkdir -p "$PREFIX/bin"
if [ -f "$PREFIX/lib/libreoffice/program/soffice" ]; then
    ln -sf "$PREFIX/lib/libreoffice/program/soffice" "$PREFIX/bin/soffice"
    ln -sf "$PREFIX/lib/libreoffice/program/soffice" "$PREFIX/bin/libreoffice"
    echo "==> LibreOffice installed successfully"
else
    echo "WARNING: soffice binary not found after extraction"
    echo "  Contents of $PREFIX/lib/libreoffice/:"
    ls -la "$PREFIX/lib/libreoffice/" 2>/dev/null || echo "  (directory does not exist)"
fi
