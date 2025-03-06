#!/bin/zsh

# Ensure a scale factor is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <scale_factor>"
    echo "Example: $0 1.5"
    exit 1
fi

# Read the scale factor
SCALE_FACTOR=$1

# Validate that the input is a number
if ! [[ "$SCALE_FACTOR" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: Scale factor must be a decimal number (e.g., 1.25, 1.5, 2.0)"
    exit 1
fi

# Set environment variable for the current Zsh session
export _JAVA_OPTIONS="-Dsun.java2d.uiScale=$SCALE_FACTOR"
echo "_JAVA_OPTIONS set to $SCALE_FACTOR for the current session."

# Persist the scale factor in ~/.zshrc
ZSHRC="$HOME/.zshrc"
if ! grep -q "export _JAVA_OPTIONS=" "$ZSHRC"; then
    echo "export _JAVA_OPTIONS=\"-Dsun.java2d.uiScale=$SCALE_FACTOR\"" >> "$ZSHRC"
else
    sed -i "s|^export _JAVA_OPTIONS=.*|export _JAVA_OPTIONS=\"-Dsun.java2d.uiScale=$SCALE_FACTOR\"|" "$ZSHRC"
fi
echo "Persisted _JAVA_OPTIONS in $ZSHRC."

# Persist in i3 config for future sessions
I3_CONFIG="$HOME/.config/i3/config"
if ! grep -q "_JAVA_OPTIONS=" "$I3_CONFIG"; then
    echo "exec --no-startup-id env _JAVA_OPTIONS=\"-Dsun.java2d.uiScale=$SCALE_FACTOR\" burpsuite" >> "$I3_CONFIG"
fi
echo "Persisted _JAVA_OPTIONS in i3 config."

# Modify Burp Suite .desktop entry
DESKTOP_FILE="/usr/share/applications/burpsuite.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    sudo sed -i "s|^Exec=.*|Exec=env _JAVA_OPTIONS=\"-Dsun.java2d.uiScale=$SCALE_FACTOR\" burpsuite|" "$DESKTOP_FILE"
    echo "Updated $DESKTOP_FILE with persistent scaling."
else
    echo "Warning: burpsuite.desktop not found! Scaling will work only for this session."
fi

echo "Restart i3 or reload Zsh for changes to take effect."

