#!/usr/bin/env bash
# Installs the DarkGold Alacritty colour scheme into ~/.config/alacritty/themes/
set -e
dir="$(cd "$(dirname "$0")" && pwd)"
dest=~/.config/alacritty/themes
mkdir -p "$dest"
[ -f "$dest/darkgold.toml" ] && cp "$dest/darkgold.toml" "$dest/darkgold.toml.bak"
cp "$dir/darkgold.toml" "$dest/"
echo "Done. Add to ~/.config/alacritty/alacritty.toml:"
echo '  [general]'
echo '  import = ["~/.config/alacritty/themes/darkgold.toml"]'
