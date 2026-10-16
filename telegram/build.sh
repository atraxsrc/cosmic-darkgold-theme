#!/usr/bin/env bash
# Build telegram/<NAME>.tdesktop-theme for Telegram Desktop: a zip of
# colors.tdesktop-theme plus the chat background. The default background is
# the theme's windowBg; --wallpaper puts one of backgrounds/*.png behind the chat,
# re-encoded to a 2560px JPEG (ImageMagick) to stay under Telegram's 5 MB limit.
#   ./telegram/build.sh
#   ./telegram/build.sh --wallpaper backgrounds/darkgold-anime.png
set -euo pipefail

NAME="cosmic-darkgold"                  # the only line that differs between rices

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$DIR/$NAME.tdesktop-theme"
WALLPAPER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --wallpaper) WALLPAPER="${2:?--wallpaper needs a .png or .jpg}"; shift 2 ;;
    -h|--help) sed -n 2,7p "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
if [[ -n "$WALLPAPER" && ! -f "$WALLPAPER" ]]; then
  echo "no such file: $WALLPAPER" >&2
  exit 1
fi

# Telegram refuses theme files over 5 MB; the wallpapers are bigger than that
LIMIT=$((5 * 1024 * 1024))
if [[ -n "$WALLPAPER" ]] && command -v convert >/dev/null 2>&1; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  convert "$WALLPAPER" -resize '2560x2560>' -strip -quality 90 "$TMP/background.jpg"
  WALLPAPER="$TMP/background.jpg"
fi

python3 -I - "$DIR/colors.tdesktop-theme" "$OUT" "$WALLPAPER" <<'EOF'
import re, struct, sys, zipfile, zlib

colors, out, wallpaper = sys.argv[1:4]
scheme = open(colors, "rb").read()

def solid_png(rgb):
    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", zlib.crc32(kind + data)))
    raw = b"\x00" + bytes(rgb)
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw))
            + chunk(b"IEND", b""))

if wallpaper:
    name = "background.jpg" if wallpaper.lower().endswith((".jpg", ".jpeg")) else "background.png"
    background = open(wallpaper, "rb").read()
else:
    bg = re.search(rb"^windowBg:\s*#([0-9a-fA-F]{6})", scheme, re.M).group(1).decode()
    name, background = "background.png", solid_png(bytes.fromhex(bg))

# fixed timestamps so a rebuild of the same input is byte-identical
stamp = (2026, 1, 1, 0, 0, 0)
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for arcname, data in (("colors.tdesktop-theme", scheme), (name, background)):
        info = zipfile.ZipInfo(arcname, stamp)
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o644 << 16
        z.writestr(info, data)
EOF

if (( $(stat -c %s "$OUT") > LIMIT )); then
  rm -f "$OUT"
  echo "theme is over Telegram's 5 MB limit; install ImageMagick (convert) or pass a smaller image" >&2
  exit 1
fi
echo "  built $OUT"
echo
echo "In Telegram Desktop: Settings -> Chat Settings -> Chat wallpaper ->"
echo "Choose from file -> pick $NAME.tdesktop-theme -> Apply this theme."
