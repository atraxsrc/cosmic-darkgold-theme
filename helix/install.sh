#!/usr/bin/env bash
# Installs the DarkGold Helix theme into ~/.config/helix/themes/
set -e
dir="$(cd "$(dirname "$0")" && pwd)"
dest=~/.config/helix/themes
mkdir -p "$dest"
[ -f "$dest/darkgold.toml" ] && cp "$dest/darkgold.toml" "$dest/darkgold.toml.bak"
cp "$dir/darkgold.toml" "$dest/"
echo 'Done. Add to ~/.config/helix/config.toml:  theme = "darkgold"'
