#!/bin/bash
# swift test を動かす。Command Line Tools だけ（Xcode なし）のときは、Swift Testing の場所を足す。
#
# Command Line Tools 26 の SwiftPM は、Swift Testing の framework があるフォルダを -F で渡さず
# （コンパイルで `no such module 'Testing'`）、実行時の場所（rpath）も足さない（`lib_TestingInterop.dylib` が読めない）。
# 16.2 では要らなかった。Xcode を使うときは要らないので、足さない。
set -euo pipefail
cd "$(dirname "$0")/.."

CLT=/Library/Developer/CommandLineTools
if [[ "$(xcode-select -p)" == "$CLT" ]]; then
  DEV="$CLT/Library/Developer"
  exec swift test \
    -Xswiftc -F -Xswiftc "$DEV/Frameworks" \
    -Xlinker -rpath -Xlinker "$DEV/Frameworks" \
    -Xlinker -rpath -Xlinker "$DEV/usr/lib" \
    "$@"
fi
exec swift test "$@"
