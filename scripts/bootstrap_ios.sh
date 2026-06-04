#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IOS="$ROOT/ios"

if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

echo "→ 同步语料 JSON"
python3 "$ROOT/scripts/embed_corpus.py"

cd "$IOS"

if command -v xcodegen >/dev/null 2>&1; then
  echo "→ 生成 Oraculo.xcodeproj"
  xcodegen generate
else
  echo "未安装 XcodeGen。请执行："
  echo "  brew install xcodegen"
  echo "  cd \"$IOS\" && xcodegen generate"
  exit 1
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "⚠ 无法运行 xcodebuild。"
  echo "  请安装完整 Xcode 并执行："
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  echo "  然后打开：$IOS/Oraculo.xcodeproj"
  exit 0
fi

DEST="$(
  xcrun simctl list devices available 2>/dev/null \
    | grep -E 'iPhone' \
    | head -1 \
    | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/' \
    || true
)"

if [[ -z "${DEST}" ]]; then
  echo "⚠ 未检测到 iOS 模拟器运行时。"
  echo "  请在 Xcode → Settings → Platforms（或 Components）中安装 iOS Simulator，"
  echo "  或终端执行：xcodebuild -downloadPlatform iOS"
  echo "  工程已就绪：open \"$IOS/Oraculo.xcodeproj\""
  exit 0
fi

echo "→ 编译模拟器（Debug），设备 ID: $DEST"
xcodebuild \
  -project Oraculo.xcodeproj \
  -scheme Oraculo \
  -destination "id=$DEST" \
  -configuration Debug \
  build

echo "✓ 编译成功。运行：open \"$IOS/Oraculo.xcodeproj\""
