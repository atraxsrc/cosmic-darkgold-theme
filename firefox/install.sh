#!/usr/bin/env bash
# Install the DarkGold / Harbor Dark userChrome/userContent stylesheets into the
# default Firefox profile, or into the profile folder given as the
# first argument. Backs up anything it replaces. Never deletes.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/chrome"
FF_DIR="${HOME}/.mozilla/firefox"

if [[ $# -ge 1 ]]; then
  # a profile folder was given, e.g. ~/.mozilla/firefox/xxxxxxxx.test
  PROFILE="${1%/}"
  [[ -d "$PROFILE" ]] || { echo "No profile folder at $PROFILE"; exit 1; }
else
  [[ -d "$FF_DIR" ]] || { echo "No Firefox directory at $FF_DIR"; exit 1; }

  # find the default-release profile
  PROFILE="$(find "$FF_DIR" -maxdepth 1 -type d -name '*.default-release' | head -n1)"
  if [[ -z "$PROFILE" ]]; then
    echo "Could not find a *.default-release profile under $FF_DIR"
    echo "Profiles present:"; find "$FF_DIR" -maxdepth 1 -type d -name '*.*' -printf '  %f\n'
    echo "Or pass a profile folder: $0 ~/.mozilla/firefox/<profile>"
    exit 1
  fi
fi
echo "Profile: $PROFILE"

DEST="$PROFILE/chrome"
mkdir -p "$DEST"

STAMP="$(date +%Y%m%d-%H%M%S)"
for f in userChrome.css userContent.css; do
  if [[ -f "$DEST/$f" ]]; then
    cp "$DEST/$f" "$DEST/$f.bak-$STAMP"
    echo "  backed up existing $f -> $f.bak-$STAMP"
  fi
  cp "$SRC/$f" "$DEST/$f"
  echo "  installed $f"
done

# prefs: the first makes Firefox read these files at all; the second takes
# the accent (URL bar ring, buttons) from the theme instead of the desktop,
# as arkenfox does, so every profile looks the same
USERJS="$PROFILE/user.js"
for PREF in \
  'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' \
  'user_pref("widget.non-native-theme.use-theme-accent", false);'; do
  NAME="$(cut -d'"' -f2 <<<"$PREF")"
  if [[ -f "$USERJS" ]] && grep -qF "\"$NAME\"" "$USERJS"; then
    echo "  $NAME already set in user.js"
  else
    echo "$PREF" >> "$USERJS"
    echo "  added $NAME to user.js"
  fi
done

echo
echo "Done. Fully restart Firefox - userChrome.css is only parsed at startup."
echo "To switch back to Monochrome or Tokyo Night, run that repo's firefox/install.sh"
