#!/usr/bin/env zsh

set -e

TARGET_DIR="$HOME/Library/xPacks/riscv-none-elf-gcc"

API_URL="https://api.github.com/repos/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/latest"
ASSET_URL=$(curl -s $API_URL | grep "browser_download_url" | grep "darwin-arm64.tar.gz" | grep -v "\.sha" | cut -d '"' -f 4)

FILENAME=$(basename "$ASSET_URL")
DOWNLOAD_PATH="/tmp/$FILENAME"

curl -L "$ASSET_URL" -o "$DOWNLOAD_PATH"

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"
tar xf "$DOWNLOAD_PATH"
UNPACKED_DIR=$(tar tf "$DOWNLOAD_PATH" | head -n1 | cut -f1 -d"/")

chmod -R -w "$UNPACKED_DIR"
echo "Unpacked to: $TARGET_DIR/$UNPACKED_DIR"

BIN_PATH="$TARGET_DIR/$UNPACKED_DIR/bin"
echo "Toolchain binaries located at: $BIN_PATH"

echo "To add this to your shell's PATH, add the following line to ~/.zshrc or ~/.bashrc:"
echo "export PATH=\"$BIN_PATH:\$PATH\""
