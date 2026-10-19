#!/bin/bash
# AnyKana.app を作って署名し、~/Applications に置く。動いている AnyKana は止める（起動はしない）。
#
# 権限（入力監視・アクセシビリティ）は、Bundle ID と署名した証明書でアプリを見分けている。
# 同じ証明書で署名し続ければ、作り直しても権限を付け直さなくてよい。
set -euo pipefail
cd "$(dirname "$0")/.."

# キーチェーンアクセスで作った、自己署名のコード署名用の証明書の名前
SIGN_IDENTITY="AnyKana Dev"

APP=.build/AnyKana.app
DEST="$HOME/Applications/AnyKana.app"

swift build -c release --product AnyKana

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/AnyKana "$APP/Contents/MacOS/AnyKana"
cp Resources/Info.plist "$APP/Contents/Info.plist"
# 画面の文言（言語ごと）
mkdir -p "$APP/Contents/Resources"
cp -R Resources/*.lproj "$APP/Contents/Resources/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --sign "$SIGN_IDENTITY" "$APP"

pkill -x AnyKana || true
mkdir -p "$HOME/Applications"
rm -rf "$DEST"
cp -R "$APP" "$DEST"
echo "置いた: ${DEST}（起動は open \"${DEST}\"）"
