#!/bin/bash
# ==============================================================================
#                 Odysseus Compilation and Packaging Script
# ==============================================================================
set -e

# App configuration parameters
APP_NAME="Odysseus"
SRC_DIR="/Users/hassan/local-ai/apps/Odysseus"
OUT_DIR="/Users/hassan/local-ai"
BUILD_DIR="$SRC_DIR/build_temp"

# Text Styling
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}===========================================${NC}"
echo -e "${BOLD}      Compiling Odysseus App              ${NC}"
echo -e "${BOLD}===========================================${NC}\n"

# 1. Clean old temporary builds
echo -e "[1/4] Cleaning old build files..."
rm -rf "$BUILD_DIR"
rm -rf "$OUT_DIR/$APP_NAME.app"

# 2. Setup bundle structure
echo -e "[2/4] Setting up App bundle structure..."
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/Resources"

# 3. Compile the Swift application
echo -e "[3/4] Compiling main.swift with swiftc..."
SDK_PATH=$(xcrun --show-sdk-path --sdk macosx)

swiftc -O \
    -target arm64-apple-macosx14.0 \
    -parse-as-library \
    -sdk "$SDK_PATH" \
    "$SRC_DIR/main.swift" \
    -o "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/Odysseus"

# 4. Copy Info.plist and finalize bundle assets
echo -e "[4/4] Finalizing bundle assets..."
cp "$SRC_DIR/Info.plist" "$BUILD_DIR/$APP_NAME.app/Contents/Info.plist"
chmod +x "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/Odysseus"

# Copy AppIcon.icns if available in source directory, otherwise fallback to existing icon
if [ -f "$SRC_DIR/AppIcon.icns" ]; then
    echo -e "Copying custom application icon..."
    cp "$SRC_DIR/AppIcon.icns" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/AppIcon.icns"
elif [ -f "/Users/hassan/local-ai/icns/Odysseus.icns" ]; then
    echo -e "Copying Odysseus icon as logo..."
    cp "/Users/hassan/local-ai/icns/Odysseus.icns" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/AppIcon.icns"
fi

# Move finalized bundle to destination workspace folder
mv "$BUILD_DIR/$APP_NAME.app" "$OUT_DIR/"

# 5. Clear quarantine attributes and sign the bundle
echo -e "Signing and registering bundle..."
xattr -cr "$OUT_DIR/$APP_NAME.app"
codesign --force --deep --sign - "$OUT_DIR/$APP_NAME.app"

# Clean up temp
rm -rf "$BUILD_DIR"

echo -e "\n${BOLD}${GREEN}===========================================${NC}"
echo -e "${BOLD}${GREEN}   Build successful! App assembled at:       ${NC}"
echo -e "${BOLD}${GREEN}   $OUT_DIR/$APP_NAME.app                   ${NC}"
echo -e "${BOLD}${GREEN}===========================================${NC}"
