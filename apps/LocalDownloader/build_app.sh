#!/usr/bin/env bash

# LocalDownloader Build Script
# Compiles main.swift and packages it into a native macOS .app bundle.

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
RED="\033[31m"
NC="\033[0m"

APP_NAME="LocalDownloader"
SRC_DIR="/Users/hassan/local-ai/apps/LocalDownloader"
OUT_DIR="/Users/hassan/local-ai"
BUILD_DIR="$SRC_DIR/build"

echo -e "${BOLD}${BLUE}===========================================${NC}"
echo -e "${BOLD}${BLUE}      Compiling LocalDownloader App        ${NC}"
echo -e "${BOLD}${BLUE}===========================================${NC}"

# 1. Clean previous build folders
echo -e "\n[1/4] Cleaning old build files..."
rm -rf "$BUILD_DIR"
rm -rf "$OUT_DIR/$APP_NAME.app"

# 2. Create the target App bundle layout
echo -e "[2/4] Setting up App bundle structure..."
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/Resources"

# 3. Compile the Swift application
echo -e "[3/4] Compiling main.swift with swiftc..."
SDK_PATH=$(xcrun --show-sdk-path --sdk macosx)

swiftc -O \
    -parse-as-library \
    -sdk "$SDK_PATH" \
    "$SRC_DIR/main.swift" \
    -o "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/LocalDownloader"

# 4. Copy Info.plist and finalize bundle
echo -e "[4/4] Finalizing bundle assets..."
cp "$SRC_DIR/Info.plist" "$BUILD_DIR/$APP_NAME.app/Contents/Info.plist"
chmod +x "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/LocalDownloader"

# Copy AppIcon.icns if available in source directory
if [ -f "$SRC_DIR/AppIcon.icns" ]; then
    echo -e "Copying custom application icon..."
    cp "$SRC_DIR/AppIcon.icns" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/AppIcon.icns"
fi

# Move the finalized app bundle to /Users/hassan/local-ai
mv "$BUILD_DIR/$APP_NAME.app" "$OUT_DIR/"

# 5. Clear quarantine attributes and apply ad-hoc code signature
echo -e "Signing and registers bundle..."
xattr -cr "$OUT_DIR/$APP_NAME.app"
codesign --force --deep --sign - "$OUT_DIR/$APP_NAME.app"

# Clean temporary build directory
rm -rf "$BUILD_DIR"

echo -e "\n${BOLD}${GREEN}===========================================${NC}"
echo -e "${BOLD}${GREEN}   Build successful! App assembled at:       ${NC}"
echo -e "${BOLD}${GREEN}   $OUT_DIR/$APP_NAME.app                  ${NC}"
echo -e "${BOLD}${GREEN}===========================================${NC}"
