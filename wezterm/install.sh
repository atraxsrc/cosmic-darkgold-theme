#!/usr/bin/env bash
# Installs the DarkGold WezTerm colour module into ~/.config/wezterm/
set -e
dir="$(cd "$(dirname "$0")" && pwd)"
dest=~/.config/wezterm
mkdir -p "$dest"
[ -f "$dest/darkgold.lua" ] && cp "$dest/darkgold.lua" "$dest/darkgold.lua.bak"
cp "$dir/darkgold.lua" "$dest/"
echo 'Done. Add to ~/.config/wezterm/wezterm.lua:  config.colors = require("darkgold")'
