#!/usr/bin/env bash
# Install this rice's colour themes into Cursor. Packs this folder into
# vscode/<name>-<version>.vsix and installs it with the editor's own CLI, so it
# shows up under Extensions and a re-run updates it in place.
#   ./vscode/install.sh                # Cursor
#   ./vscode/install.sh code codium    # VS Code / VSCodium instead (any CLI name works)
# Then press Ctrl+K Ctrl+T in the editor and pick the theme (see vscode/README.md).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
  -h|--help) sed -n 2,7p "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac
editors=("$@")
[[ ${#editors[@]} -eq 0 ]] && editors=(cursor)

# name and version come from package.json; the .vsix is a zip with the
# extension under extension/ plus the two manifest files the installer reads
VSIX="$(python3 -I - "$DIR" <<'EOF'
import json, os, sys, zipfile
from xml.sax.saxutils import escape

d = sys.argv[1]
pkg = json.load(open(os.path.join(d, "package.json")))
out = os.path.join(d, f"{pkg['name']}-{pkg['version']}.vsix")

files = {
    "extension/package.json": os.path.join(d, "package.json"),
    "extension/README.md": os.path.join(d, "README.md"),
    "extension/LICENSE.txt": os.path.join(d, "..", "LICENSE"),
    "extension/icon.png": os.path.join(d, "icon.png"),
}
for theme in pkg["contributes"]["themes"]:
    rel = os.path.normpath(theme["path"])
    files[f"extension/{rel}"] = os.path.join(d, rel)

content_types = """<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension=".json" ContentType="application/json"/>
<Default Extension=".md" ContentType="text/markdown"/>
<Default Extension=".png" ContentType="image/png"/>
<Default Extension=".txt" ContentType="text/plain"/>
<Default Extension=".vsixmanifest" ContentType="text/xml"/>
</Types>
"""
manifest = f"""<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011" xmlns:d="http://schemas.microsoft.com/developer/vsx-schema-design/2011">
  <Metadata>
    <Identity Language="en-US" Id="{escape(pkg['name'])}" Version="{escape(pkg['version'])}" Publisher="{escape(pkg['publisher'])}" />
    <DisplayName>{escape(pkg['displayName'])}</DisplayName>
    <Description xml:space="preserve">{escape(pkg['description'])}</Description>
    <Tags>{escape(','.join(pkg.get('keywords', [])))}</Tags>
    <Categories>{escape(','.join(pkg['categories']))}</Categories>
    <GalleryFlags>Public</GalleryFlags>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="{escape(pkg['engines']['vscode'])}" />
      <Property Id="Microsoft.VisualStudio.Services.Links.Source" Value="{escape(pkg['repository']['url'])}" />
      <Property Id="Microsoft.VisualStudio.Services.Branding.Color" Value="{escape(pkg['galleryBanner']['color'])}" />
      <Property Id="Microsoft.VisualStudio.Services.Branding.Theme" Value="{escape(pkg['galleryBanner']['theme'])}" />
    </Properties>
    <License>extension/LICENSE.txt</License>
    <Icon>extension/icon.png</Icon>
  </Metadata>
  <Installation>
    <InstallationTarget Id="Microsoft.VisualStudio.Code" />
  </Installation>
  <Dependencies />
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true" />
    <Asset Type="Microsoft.VisualStudio.Services.Content.Details" Path="extension/README.md" Addressable="true" />
    <Asset Type="Microsoft.VisualStudio.Services.Content.License" Path="extension/LICENSE.txt" Addressable="true" />
    <Asset Type="Microsoft.VisualStudio.Services.Icons.Default" Path="extension/icon.png" Addressable="true" />
  </Assets>
</PackageManifest>
"""
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", content_types)
    z.writestr("extension.vsixmanifest", manifest)
    for arc, src in files.items():
        z.write(src, arc)
print(out)
EOF
)"
echo "  built $(basename "$VSIX")"

installed=0
for cli in "${editors[@]}"; do
  if command -v "$cli" >/dev/null 2>&1; then
    "$cli" --install-extension "$VSIX" --force 2>&1 | sed "/^$/d; s/^/  $cli: /"
    installed=1
  else
    echo "  $cli: not found on PATH, skipped"
  fi
done

# the theme labels, dark first, for the closing hint
mapfile -t labels < <(python3 -I -c '
import json, sys
for t in json.load(open(sys.argv[1]))["contributes"]["themes"]:
    print(("dark" if t["uiTheme"] != "vs" else "light") + "\t" + t["label"])
' "$DIR/package.json")

echo
if [[ $installed -eq 1 ]]; then
  echo "Done. In the editor press Ctrl+K Ctrl+T and pick one of:"
  for l in "${labels[@]}"; do echo "  ${l#*$'\t'} (${l%%$'\t'*})"; done
  if [[ ${#labels[@]} -eq 2 ]]; then
    echo "To follow COSMIC's Dark / Light toggle, add to Cursor's settings.json:"
    echo "  \"window.autoDetectColorScheme\": true,"
    echo "  \"workbench.preferredDarkColorTheme\": \"${labels[0]#*$'\t'}\","
    echo "  \"workbench.preferredLightColorTheme\": \"${labels[1]#*$'\t'}\""
  fi
else
  echo "No editor CLI found. In the editor: Extensions -> ... menu -> Install from VSIX ->"
  echo "  $VSIX"
fi
