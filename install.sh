#!/bin/sh
# Symlink (or copy) the plugin into the DMS plugin directory, then scan for it
# in DMS Settings → Plugins.
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins"
mkdir -p "$DEST"
if [ "$1" = "copy" ]; then
    rm -rf "$DEST/HiraganaWidget"
    cp -rL "$DIR/HiraganaWidget" "$DEST/HiraganaWidget"
    echo "copied to $DEST/HiraganaWidget"
else
    ln -sfn "$DIR/HiraganaWidget" "$DEST/HiraganaWidget"
    echo "linked $DEST/HiraganaWidget -> $DIR/HiraganaWidget"
fi
if command -v dms >/dev/null 2>&1; then
    dms ipc call plugins scan 2>/dev/null || true
fi
echo "Now: DMS Settings → Plugins → Scan → enable 'Hiragana'"
echo "     bar pill:       Settings → DankBar → layout → add hiraganaWidget"
echo "     desktop widget: Settings → Desktop Widgets → add it, right-click drag to move/resize"
