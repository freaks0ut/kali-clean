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

echo "Applying system-wide scaling for GTK and QT applications (excluding Firefox, VS Code, and Burp Suite)..."

### APPLY SCALING WITHOUT CHANGING DPI OR TOUCHING FIREFOX/VSCODE/BURP ###

# GTK applications (File managers, settings dialogs, GUI apps)
export GDK_SCALE=$SCALE_FACTOR
export GDK_DPI_SCALE=$(bc <<< "scale=2; 1/$SCALE_FACTOR")

PROFILE_FILE="$HOME/.profile"

if ! grep -q "export GDK_SCALE=" "$PROFILE_FILE"; then
    echo "export GDK_SCALE=$SCALE_FACTOR" >> "$PROFILE_FILE"
    echo "export GDK_DPI_SCALE=$(bc <<< "scale=2; 1/$SCALE_FACTOR")" >> "$PROFILE_FILE"
else
    sed -i "s|^export GDK_SCALE=.*|export GDK_SCALE=$SCALE_FACTOR|" "$PROFILE_FILE"
    sed -i "s|^export GDK_DPI_SCALE=.*|export GDK_DPI_SCALE=$(bc <<< "scale=2; 1/$SCALE_FACTOR")|" "$PROFILE_FILE"
fi
echo "Persisted GTK scaling in $PROFILE_FILE."

# QT applications (KDE apps, VirtualBox, etc.)
export QT_SCALE_FACTOR=$SCALE_FACTOR
export QT_AUTO_SCREEN_SCALE_FACTOR=0  # Ensure manual scaling is used

if ! grep -q "export QT_SCALE_FACTOR=" "$PROFILE_FILE"; then
    echo "export QT_SCALE_FACTOR=$SCALE_FACTOR" >> "$PROFILE_FILE"
    echo "export QT_AUTO_SCREEN_SCALE_FACTOR=0" >> "$PROFILE_FILE"
else
    sed -i "s|^export QT_SCALE_FACTOR=.*|export QT_SCALE_FACTOR=$SCALE_FACTOR|" "$PROFILE_FILE"
    sed -i "s|^export QT_AUTO_SCREEN_SCALE_FACTOR=.*|export QT_AUTO_SCREEN_SCALE_FACTOR=0|" "$PROFILE_FILE"
fi
echo "Persisted QT scaling in $PROFILE_FILE."

# Reload environment variables for current session
source "$PROFILE_FILE"

echo "Scaling applied for GTK and QT applications. Restart applications for changes to take effect."

