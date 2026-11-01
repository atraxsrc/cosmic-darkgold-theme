#!/usr/bin/env bash
# Installs the DarkGold Ghostty theme into ~/.config/ghostty/themes/
set -e
dir="$(cd "$(dirname "$0")" && pwd)"
dest=~/.config/ghostty/themes
mkdir -p "$dest"
[ -f "$dest/DarkGold" ] && cp "$dest/DarkGold" "$dest/DarkGold.bak"
cp "$dir/DarkGold" "$dest/"
echo "Done. Add to ~/.config/ghostty/config:  theme = DarkGold"
echo "(or  theme = dark:DarkGold,light:WhiteGold  to follow COSMIC's toggle), then reload: Ctrl+Shift+,"
