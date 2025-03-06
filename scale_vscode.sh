#!/bin/zsh

# Ensure a scale factor is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <scale_factor>"
    echo "Example: $0 1.5"
    exit 1
fi

SCALE_FACTOR=$1

# Validate input
if ! [[ "$SCALE_FACTOR" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: Scale factor must be a decimal number (e.g., 1.25, 1.5, 2.0)"
    exit 1
fi

echo "Closing VS Code..."
killall -9 code 2>/dev/null
sleep 2  # Ensure processes are terminated

### APPLY VS CODE SCALING ###
# Electron-based apps like VS Code use `ELECTRON_SCALE`
export ELECTRON_SCALE=$SCALE_FACTOR

PROFILE_FILE="$HOME/.profile"

if ! grep -q "export ELECTRON_SCALE=" "$PROFILE_FILE"; then
    echo "export ELECTRON_SCALE=$SCALE_FACTOR" >> "$PROFILE_FILE"
else
    sed -i "s|^export ELECTRON_SCALE=.*|export ELECTRON_SCALE=$SCALE_FACTOR|" "$PROFILE_FILE"
fi
echo "Persisted VS Code scaling in $PROFILE_FILE."

# Modify VS Code .desktop entry for GUI-based launches
DESKTOP_FILE="/usr/share/applications/code.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    sudo sed -i "s|^Exec=.*|Exec=env ELECTRON_SCALE=$SCALE_FACTOR code --force-device-scale-factor=$SCALE_FACTOR|" "$DESKTOP_FILE"
    echo "Updated $DESKTOP_FILE with persistent scaling."
else
    echo "Warning: VS Code .desktop entry not found! Scaling will work only for this session."
fi

# Restart VS Code
echo "Restarting VS Code..."

# Debugging - Start Application again
# code --force-device-scale-factor=$SCALE_FACTOR &
# echo "VS Code is now running with scaling factor $SCALE_FACTOR."

