#!/bin/zsh

# Ensure a scale factor is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <scale_factor>"
    echo "Example: $0 2"
    exit 1
fi

SCALE_FACTOR=$1

# Validate input
if ! [[ "$SCALE_FACTOR" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: Scale factor must be a decimal number (e.g., 1.25, 1.5, 2.0)"
    exit 1
fi

echo "Closing Firefox completely..."
killall -9 firefox-esr
killall -9 firefox
sleep 2  # Wait for processes to terminate

# Detect the correct Firefox profile (prefers ESR)
FIREFOX_PROFILE=$(find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.default-esr" | head -n 1)

if [ -z "$FIREFOX_PROFILE" ]; then
    echo "Error: No Firefox ESR profile found!"
    exit 1
fi

PREFS_FILE="$FIREFOX_PROFILE/prefs.js"
USER_FILE="$FIREFOX_PROFILE/user.js"

# Remove old settings
sed -i '/layout.css.devPixelsPerPx/d' "$PREFS_FILE"

# Add new scaling setting to prefs.js
echo "user_pref(\"layout.css.devPixelsPerPx\", \"$SCALE_FACTOR\");" >> "$PREFS_FILE"
echo "Updated Firefox prefs.js to scale at $SCALE_FACTOR."

# Ensure persistence with user.js
echo "user_pref(\"layout.css.devPixelsPerPx\", \"$SCALE_FACTOR\");" > "$USER_FILE"
chmod 644 "$USER_FILE"
echo "Persisted Firefox scaling with user.js."

# DEBUGGING - Start Application if required
# echo "Restarting Firefox..."
# firefox-esr &

