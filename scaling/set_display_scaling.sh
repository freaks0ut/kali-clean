#!/bin/bash

export DISPLAY=:0
sleep 2  # Ensure display is fully initialized

# ✅ Print the current resolution
CURRENT_RESOLUTION=$(xrandr | grep '*' | awk '{print $1}')
echo "📺 Current Resolution: $CURRENT_RESOLUTION"

# ✅ Get all available resolutions from VMware Fusion
AVAILABLE_MODES=$(xrandr | awk '{print $1}' | grep -E "^[0-9]+x[0-9]+" | sort -u)

# ✅ Ask the user to select a resolution
echo "Choose screen resolution:"
echo "0: MacBook 13.3'' default resolution (2560x1600)"
echo "1: External display resolution (2560x1440)"
read -p "Enter 0 or 1: " RESOLUTION_OPTION

if [[ "$RESOLUTION_OPTION" == "0" ]]; then
    NEW_RESOLUTION="2560x1600"
elif [[ "$RESOLUTION_OPTION" == "1" ]]; then
    NEW_RESOLUTION="2560x1440_60.00"  # Ensure exact match
else
    echo "❌ Invalid option. Exiting."
    exit 1
fi

# ✅ Check if the selected resolution is available
if echo "$AVAILABLE_MODES" | grep -q "^${NEW_RESOLUTION}$"; then
    echo "Setting resolution to $NEW_RESOLUTION..."
    xrandr --output Virtual-1 --mode "$NEW_RESOLUTION"
else
    echo "⚠️ Resolution $NEW_RESOLUTION is not available. Attempting to add it..."

    # ✅ Only attempt to add 2560x1440 if missing
    if [[ "$NEW_RESOLUTION" == "2560x1440_60.00" ]]; then
        MODELINE=$(cvt 2560 1440 60 | grep Modeline | cut -d ' ' -f 2-)

        if [[ -n "$MODELINE" ]]; then
            echo "Adding new mode: $NEW_RESOLUTION"
            xrandr --newmode $MODELINE
            xrandr --addmode Virtual-1 "$NEW_RESOLUTION"

            # ✅ Apply the newly added resolution
            echo "Applying new resolution..."
            xrandr --output Virtual-1 --mode "$NEW_RESOLUTION"
        else
            echo "❌ Error generating modeline for $NEW_RESOLUTION."
            exit 1
        fi
    else
        echo "❌ Error: Resolution $NEW_RESOLUTION is not available and cannot be added."
        exit 1
    fi
fi

# ✅ Verify resolution change (fix resolution name mismatch)
NEW_CURRENT_RESOLUTION=$(xrandr | grep '*' | awk '{print $1}')

# ✅ Normalize the resolution name before comparing
NORMALIZED_CURRENT_RESOLUTION=$(echo "$NEW_CURRENT_RESOLUTION" | sed 's/_60.00//')
NORMALIZED_NEW_RESOLUTION=$(echo "$NEW_RESOLUTION" | sed 's/_60.00//')

if [[ "$NORMALIZED_CURRENT_RESOLUTION" == "$NORMALIZED_NEW_RESOLUTION" ]]; then
    echo "✅ Resolution successfully changed to $NEW_CURRENT_RESOLUTION!"
else
    echo "❌ Resolution change failed. Expected: $NEW_RESOLUTION, but got: $NEW_CURRENT_RESOLUTION"
fi
