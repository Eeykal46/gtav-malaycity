#!/bin/bash
# Usage: ./build_ipa.sh GTAV-unsigned.ipa out.ipa   (run on macOS, Xcode installed)
set -euo pipefail
IN="$1"; OUT="$2"; W=$(mktemp -d)
unzip -q "$IN" -d "$W"; APP=$(echo "$W"/Payload/*.app)
xcrun -sdk iphoneos clang -arch arm64 -miniphoneos-version-min=15.0 -dynamiclib -fobjc-arc \
  -framework UIKit -framework Foundation -install_name @rpath/HudSkin.dylib \
  -I src -o "$APP/Frameworks/HudSkin.dylib" src/HudSkin.m
# MPLPlayButton is not referenced by type in HudSkin.m, so no private headers are needed.
python3 tools/inject.py "$APP/$(/usr/libexec/PlistBuddy -c 'Print CFBundleExecutable' "$APP/Info.plist")" @executable_path/Frameworks/HudSkin.dylib
(cd "$W" && zip -qry "$OLDPWD/$OUT" Payload)
echo "built $OUT (unsigned; sign with AltStore/SideStore)"
