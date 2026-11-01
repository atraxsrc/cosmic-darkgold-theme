#!/usr/bin/env bash
# Installs the DarkGold delta config into ~/.config/delta/. It does not edit
# ~/.gitconfig: add the [include] it prints.
set -e
dir="$(cd "$(dirname "$0")" && pwd)"
dest=~/.config/delta
mkdir -p "$dest"
[ -f "$dest/darkgold.gitconfig" ] && cp "$dest/darkgold.gitconfig" "$dest/darkgold.gitconfig.bak"
cp "$dir/darkgold.gitconfig" "$dest/"
if [ -f ~/.gitconfig ] && grep -qF "delta/darkgold.gitconfig" ~/.gitconfig; then
    echo "Done. ~/.gitconfig already includes it."
else
    echo "Done. Add to ~/.gitconfig:"
    echo "  [include]"
    echo "      path = ~/.config/delta/darkgold.gitconfig"
fi
echo "Needs the bat DarkGold theme for the code colours: ./bat/install.sh"
