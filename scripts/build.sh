#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/src/DeepSeek 建议回复.cherri"
BUILD_DIR="$ROOT_DIR/dist"
CHERRI_UNSIGNED_FILE="$ROOT_DIR/src/DeepSeek 建议回复_unsigned.shortcut"
UNSIGNED_FILE="$BUILD_DIR/DeepSeek 建议回复.unsigned.shortcut"
SIGNED_FILE="$BUILD_DIR/DeepSeek 建议回复.shortcut"

if ! command -v cherri >/dev/null 2>&1; then
    echo "未找到 Cherri。请先运行："
    echo "  brew tap electrikmilk/cherri"
    echo "  brew install electrikmilk/cherri/cherri"
    exit 1
fi

mkdir -p "$BUILD_DIR"

echo "正在编译 Shortcut..."
cherri "$SOURCE_FILE" \
    --skip-sign \
    --derive-uuids \
    --no-ansi

mv "$CHERRI_UNSIGNED_FILE" "$UNSIGNED_FILE"

if command -v shortcuts >/dev/null 2>&1; then
    echo "正在使用 Apple shortcuts CLI 签名..."
    shortcuts sign \
        --mode anyone \
        --input "$UNSIGNED_FILE" \
        --output "$SIGNED_FILE"
    echo "构建完成：$SIGNED_FILE"
else
    echo "当前系统没有 Apple shortcuts CLI，已生成未签名文件："
    echo "  $UNSIGNED_FILE"
    echo "请在 macOS 上签名后再导入 iPhone。"
fi
