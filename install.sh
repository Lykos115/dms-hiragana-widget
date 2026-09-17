#!/bin/sh
# Symlink (or copy) the plugin into the DMS plugin directory, then scan for it
# in DMS Settings → Plugins.
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins"
mkdir -p "$DEST"
if [ "$1" = "copy" ]; then
    rm -rf "$DEST/JlabWidget"
    cp -rL "$DIR/JlabWidget" "$DEST/JlabWidget"
    echo "copied to $DEST/JlabWidget"
else
    # an earlier "copy" install leaves a real directory; ln -sfn would put the
    # link inside it instead of replacing it
    [ -d "$DEST/JlabWidget" ] && [ ! -L "$DEST/JlabWidget" ] && rm -rf "$DEST/JlabWidget"
    ln -sfn "$DIR/JlabWidget" "$DEST/JlabWidget"
    echo "linked $DEST/JlabWidget -> $DIR/JlabWidget"
fi
echo "Now: DMS Settings → Plugins → Scan → enable 'Jlab sentences'"
echo "     bar pill:       Settings → DankBar → layout → add jlabWidget"
echo "     desktop widget: Settings → Desktop Widgets → add it, right-click drag to move/resize"
