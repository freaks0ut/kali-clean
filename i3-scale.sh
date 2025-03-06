#!/bin/bash

# Set Directory
SCRIPT_DIR="$(dirname "$0")"

# Set scaling factor for applications
read -p "Enter scaling factor for applications (e.g., 1.0 for normal, 1.5 for HiDPI, 2.0 for Retina displays, default: $SCALING_FACTOR): " USER_SCALING_FACTOR
SCALING_FACTOR="${USER_SCALING_FACTOR:-$SCALING_FACTOR}"

# Ensure SCALING_FACTOR is set and has the correct format
SCALING_FACTOR=$(echo "$SCALING_FACTOR" | tr ',' '.' | sed 's/[^0-9.]//g')

# Check if SCALING_FACTOR is empty or invalid
if [[ -z "$SCALING_FACTOR" || ! "$SCALING_FACTOR" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "❌ Error: SCALING_FACTOR is invalid: '$SCALING_FACTOR'"
    exit 1
fi

"$SCRIPT_DIR/set_display_scaling.sh" "$SCALING_FACTOR"

# Set Font Sizes for Terminal
echo "Change Font Sizes"
"$SCRIPT_DIR/set_fonts.sh"

# Restart i3 to apply changes
i3-msg reload

# Call separate scripts to scale applications
echo "Change Firefox Scaling"
"$SCRIPT_DIR/scale_firefox.sh" "$SCALING_FACTOR"
echo "Change Visual Studio Code Scaling"
"$SCRIPT_DIR/scale_vscode.sh" "$SCALING_FACTOR"
"$SCRIPT_DIR/scale_gtk.sh" "$SCALING_FACTOR"
"$SCRIPT_DIR/scale_burpsuite.sh" "$SCALING_FACTOR"
echo "✅ Scaling factor applied: $SCALING_FACTOR"

echo "✅ All changes applied successfully!"