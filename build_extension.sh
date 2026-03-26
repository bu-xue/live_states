#!/bin/bash

# Exit on error
set -e

# Define paths
PROJECT_ROOT=$(pwd)
EXTENSION_SRC="$PROJECT_ROOT/extension/live_states_devtools"
EXTENSION_TARGET="$PROJECT_ROOT/extension/devtools/build"

echo "🚀 Starting LiveStates DevTools Extension build..."

# 1. Clean and build the extension web app
echo "📦 Building Extension..."
cd "$EXTENSION_SRC"
flutter clean
flutter pub get
flutter build web --release --wasm

# 2. Prepare target directory
echo "📂 Preparing target directory: $EXTENSION_TARGET"
cd "$PROJECT_ROOT"
rm -rf "$EXTENSION_TARGET"
mkdir -p "$EXTENSION_TARGET"

# 3. Copy build artifacts
echo "🚚 Copying artifacts to main package..."
cp -r "$EXTENSION_SRC/build/web/"* "$EXTENSION_TARGET"

echo "✅ Build complete!"
