#!/usr/bin/env bash
# Installs the DarkGold kitty colour scheme into ~/.config/kitty/themes/
set -e
dir="$(cd "$(dirname "$0")" && pwd)"
dest=~/.config/kitty/themes
mkdir -p "$dest"
[ -f "$dest/DarkGold.conf" ] && cp "$dest/DarkGold.conf" "$dest/DarkGold.conf.bak"
cp "$dir/DarkGold.conf" "$dest/"
echo "Done. Add to ~/.config/kitty/kitty.conf:  include themes/DarkGold.conf"
echo "then reload kitty (Ctrl+Shift+F5)."
