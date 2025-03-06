#!/bin/bash

# Set script directory
SCRIPT_DIR="$(dirname "$0")"

# Choose resolution
echo "Choose screen resolution:"
echo "0: MacBook 14'' default resolution (3024x1964)"
echo "1: 2560x1440 (for external displays)"
read -p "Enter 0 or 1: " RESOLUTION_CHOICE

# Set the resolution
if [[ "$RESOLUTION_CHOICE" == "0" ]]; then
    RESOLUTION="3024x1964"
elif [[ "$RESOLUTION_CHOICE" == "1" ]]; then
    RESOLUTION="2560x1440"
else
    echo "Invalid choice."
    exit 1
fi

# Ensure bc is installed
if ! command -v bc &> /dev/null; then
    echo "❌ Error: bc is not installed. Install it with: sudo apt install bc"
    exit 1
fi

# Apply resolution
if ! xrandr | grep -q "$RESOLUTION"; then
    echo "Creating new resolution: $RESOLUTION"
    MODELINE=$(cvt $(echo $RESOLUTION | cut -dx -f1) $(echo $RESOLUTION | cut -dx -f2) 60 | grep Modeline | cut -d ' ' -f 2-)
    xrandr --newmode $MODELINE
    xrandr --addmode Virtual-1 $RESOLUTION
fi
xrandr --output Virtual-1 --mode $RESOLUTION
echo "✅ Resolution applied: $RESOLUTION"

# Ensure SCALING_FACTOR is passed as an argument
if [ -z "$1" ]; then
    echo "❌ Error: No scaling factor provided!"
    exit 1
fi

SCALING_FACTOR="$1"

# Ask user for custom DPI value (independent of scaling)
read -p "Enter DPI value (default: 192 for HiDPI screens): " USER_DPI_VALUE
DPI_VALUE="${USER_DPI_VALUE:-192}"

# Apply custom DPI value
echo "Xft.dpi: $DPI_VALUE" | xrdb -merge
echo "✅ DPI set to: $DPI_VALUE"

echo "✅ Display settings and DPI applied independently of scaling!"
