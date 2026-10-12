#!/usr/bin/env bash
# Install the Cosmic-DarkGold icon pack and make it the COSMIC icon theme.
#
#   ./icons/install.sh                    # Gold folders: download, install, activate
#   ./icons/install.sh --variant Red      # another folder color (see --list)
#   ./icons/install.sh --no-activate      # install only, keep the current icon theme
#   ./icons/install.sh --list             # show the folder colors
#
# Downloads Cosmic-DarkGold-<Variant>.tar.xz from the latest release of
# https://github.com/atraxsrc/cosmic-icon-themes, checks it against the
# release's SHA256SUMS, and installs it to ~/.local/share/icons. Activating
# backs up the previous COSMIC icon setting (.bak-<timestamp>). Safe to run again.
set -euo pipefail

THEME="DarkGold"
VARIANTS=(Gold Red Dark)
VARIANT="Gold"
BASE="${COSMIC_ICONS_URL:-https://github.com/atraxsrc/cosmic-icon-themes/releases/latest/download}"
DEST="$HOME/.local/share/icons"
SETTING="$HOME/.config/cosmic/com.system76.CosmicTk/v1/icon_theme"
STAMP="$(date +%Y%m%d-%H%M%S)"
ACTIVATE=true

usage() {
  sed -n '4,7s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --variant)     VARIANT="${2:-}"; shift ;;
    --variant=*)   VARIANT="${1#--variant=}" ;;
    --no-activate) ACTIVATE=false ;;
    --list)        printf '%s\n' "${VARIANTS[@]}"; exit 0 ;;
    -h|--help)     usage; exit 0 ;;
    *)             echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
  shift
done

if [[ " ${VARIANTS[*]} " != *" $VARIANT "* ]]; then
  echo "Unknown variant '$VARIANT'. Pick one of: ${VARIANTS[*]}"
  exit 1
fi
for cmd in curl tar xz sha256sum; do
  command -v "$cmd" >/dev/null || { echo "Needs $cmd"; exit 1; }
done

PACK="Cosmic-$THEME-$VARIANT"
mkdir -p "$DEST"
# stage inside DEST so the final move is a rename on the same filesystem
stage="$(mktemp -d "$DEST/.$PACK.new-XXXXXX")"
trap 'rm -rf -- "$stage"' EXIT

# 1. download and verify ---------------------------------------------------
echo "Downloading $PACK"
curl -fsSL -o "$stage/$PACK.tar.xz" "$BASE/$PACK.tar.xz"
curl -fsSL -o "$stage/SHA256SUMS" "$BASE/SHA256SUMS"
if ! (cd "$stage" && grep " $PACK.tar.xz\$" SHA256SUMS | sha256sum -c --quiet -); then
  echo "Checksum mismatch for $PACK.tar.xz, nothing installed"
  exit 1
fi

# 2. install ---------------------------------------------------------------
tar -C "$stage" -xJf "$stage/$PACK.tar.xz"
[[ -f "$stage/$PACK/index.theme" ]] || { echo "Archive has no $PACK/index.theme"; exit 1; }
if [[ -d "$DEST/$PACK" ]] && diff -r --no-dereference -q -x icon-theme.cache "$stage/$PACK" "$DEST/$PACK" >/dev/null 2>&1; then
  echo "  $PACK already up to date"
else
  rm -rf -- "${DEST:?}/$PACK"
  mv -- "$stage/$PACK" "$DEST/$PACK"
  echo "  installed $DEST/$PACK"
fi
if command -v gtk-update-icon-cache >/dev/null; then
  gtk-update-icon-cache -q -f "$DEST/$PACK" 2>/dev/null || true
fi

# 3. activate --------------------------------------------------------------
if $ACTIVATE; then
  want="\"$PACK\""
  if [[ -f "$SETTING" && "$(cat "$SETTING")" == "$want" ]]; then
    echo "COSMIC icon theme already $PACK"
  else
    mkdir -p "$(dirname "$SETTING")"
    if [[ -f "$SETTING" ]]; then
      cp -p "$SETTING" "$SETTING.bak-$STAMP"
      echo "  backup: $SETTING.bak-$STAMP"
    fi
    printf '%s' "$want" > "$SETTING"
    echo "COSMIC icon theme set to $PACK"
  fi
  # GTK apps outside COSMIC
  if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface icon-theme "$PACK" 2>/dev/null || true
  fi
  echo "Restart open apps (Files caches icons per window) to see the new folders."
fi
