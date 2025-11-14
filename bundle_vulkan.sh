#!/bin/bash
# Script to bundle MoltenVK with your LÖVR app for distribution
# Usage: ./bundle_vulkan.sh path/to/YourApp.app

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to-app-bundle>"
    echo "Example: $0 build/lovr.app"
    exit 1
fi

APP_BUNDLE="$1"
FRAMEWORKS_DIR="${APP_BUNDLE}/Contents/Frameworks"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: App bundle not found: $APP_BUNDLE"
    exit 1
fi

# Create Frameworks directory if it doesn't exist
mkdir -p "$FRAMEWORKS_DIR"

# Find MoltenVK library
MOLTENVK_LIB=""
if [ -f "/opt/homebrew/lib/libMoltenVK.dylib" ]; then
    MOLTENVK_LIB="/opt/homebrew/lib/libMoltenVK.dylib"
elif [ -f "/usr/local/lib/libMoltenVK.dylib" ]; then
    MOLTENVK_LIB="/usr/local/lib/libMoltenVK.dylib"
else
    echo "Error: Could not find libMoltenVK.dylib"
    echo "Make sure MoltenVK is installed: brew install molten-vk"
    exit 1
fi

# Find Vulkan loader
VULKAN_LIB=""
if [ -f "/opt/homebrew/lib/libvulkan.1.dylib" ]; then
    VULKAN_LIB="/opt/homebrew/lib/libvulkan.1.dylib"
elif [ -f "/usr/local/lib/libvulkan.1.dylib" ]; then
    VULKAN_LIB="/usr/local/lib/libvulkan.1.dylib"
else
    echo "Error: Could not find libvulkan.1.dylib"
    echo "Make sure Vulkan is installed: brew install vulkan-loader"
    exit 1
fi

# Copy libraries
echo "Copying MoltenVK to app bundle..."
cp "$MOLTENVK_LIB" "$FRAMEWORKS_DIR/libMoltenVK.dylib"
cp "$VULKAN_LIB" "$FRAMEWORKS_DIR/libvulkan.1.dylib"

# Update library paths using install_name_tool
echo "Fixing library paths..."

# Get the actual paths (following symlinks)
MOLTENVK_REAL=$(readlink -f "$MOLTENVK_LIB" 2>/dev/null || realpath "$MOLTENVK_LIB")
VULKAN_REAL=$(readlink -f "$VULKAN_LIB" 2>/dev/null || realpath "$VULKAN_LIB")

# Update MoltenVK to use bundled Vulkan
install_name_tool -id "@rpath/libMoltenVK.dylib" "$FRAMEWORKS_DIR/libMoltenVK.dylib" 2>/dev/null
install_name_tool -id "@rpath/libvulkan.1.dylib" "$FRAMEWORKS_DIR/libvulkan.1.dylib" 2>/dev/null

# Update MoltenVK's dependency on Vulkan
install_name_tool -change "$VULKAN_REAL" "@rpath/libvulkan.1.dylib" "$FRAMEWORKS_DIR/libMoltenVK.dylib" 2>/dev/null

echo "Done! Vulkan libraries have been bundled."
echo "Your app should now work on systems without Vulkan installed."

