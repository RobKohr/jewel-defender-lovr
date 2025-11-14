#!/bin/bash
# Start script for Jewel Defender LÖVR game
# Runs in desktop/simulator mode (not VR)

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Path to the LÖVR executable
LOVR_BIN="${SCRIPT_DIR}/../lovr/build/bin/lovr"

# Check if LÖVR binary exists
if [ ! -f "$LOVR_BIN" ]; then
    echo "Error: LÖVR binary not found at $LOVR_BIN"
    echo "Please make sure you've built LÖVR first."
    exit 1
fi

# Set library path for Vulkan/MoltenVK
export DYLD_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_LIBRARY_PATH

# Run LÖVR in simulator mode (desktop mode, not VR)
# Pass the current directory as the game source
cd "$SCRIPT_DIR"
echo "Starting LÖVR from: $SCRIPT_DIR"
echo "Running: $LOVR_BIN --simulator ."
"$LOVR_BIN" --simulator . 2>&1

