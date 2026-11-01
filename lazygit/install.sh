#!/usr/bin/env bash
# Installs the DarkGold lazygit colours beside your own config.yml
set -e
dir="$(cd "$(dirname "$0")" && pwd)"
dest=~/.config/lazygit
mkdir -p "$dest"
[ -f "$dest/darkgold.yml" ] && cp "$dest/darkgold.yml" "$dest/darkgold.yml.bak"
cp "$dir/darkgold.yml" "$dest/"
echo "Done. zsh/darkgold.zsh points LG_CONFIG_FILE at config.yml plus darkgold.yml; without it:"
echo "  export LG_CONFIG_FILE=\"\$HOME/.config/lazygit/config.yml,\$HOME/.config/lazygit/darkgold.yml\""
