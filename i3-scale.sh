#!/bin/bash

# Choose resolution
echo "Choose screen resolution:"
echo "0: MacBook 14'' default resolution (3024x1964)"
echo "1: 2560x1440 (for external displays)"
read -p "Enter 0 or 1: " RESOLUTION_CHOICE

# Set the resolution
if [[ "$RESOLUTION_CHOICE" == "0" ]]; then
    RESOLUTION="3024x1964"
    SCALING_FACTOR="2.0"
elif [[ "$RESOLUTION_CHOICE" == "1" ]]; then
    RESOLUTION="2560x1440"
    SCALING_FACTOR="1.5"
else
    echo "Invalid choice."
    exit 1
fi

# Ensure bc is installed
if ! command -v bc &> /dev/null; then
    echo "Error: bc is not installed. Install it with: sudo apt install bc"
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

# Compute DPI value correctly
DPI_VALUE=$(echo "$SCALING_FACTOR * 96" | bc -l)

# Apply DPI settings
echo "Xft.dpi: $DPI_VALUE" | xrdb -merge
gsettings set org.gnome.desktop.interface scaling-factor $(printf "%.0f" "$SCALING_FACTOR") 2>/dev/null || echo "⚠️ GTK scaling might not be supported."
export GDK_SCALE=$(printf "%.0f" "$SCALING_FACTOR")
export QT_SCALE_FACTOR=$SCALING_FACTOR
echo "✅ Scaling factor applied: $SCALING_FACTOR"

# Prompt for font sizes
CURRENT_TERM_FONT=$(grep -A2 "\[font.normal\]" ~/.config/alacritty/alacritty.toml | grep "size =" | cut -d= -f2 | tr -d ' ')
read -p "Enter Terminal Font Size (recommended: 16-18, current: $CURRENT_TERM_FONT): " TERM_FONT_SIZE

CURRENT_ROFI_FONT=$(grep "font:" ~/.config/rofi/config.rasi | cut -d'"' -f2)
read -p "Enter CMD+D Popup Font Size (recommended: 14-16, current: $CURRENT_ROFI_FONT): " ROFI_FONT_SIZE

CURRENT_HEADER_FONT=$(grep "font pango:" ~/.config/i3/config | cut -d' ' -f3-)
read -p "Enter i3 Header Font Size (recommended: 14-16, current: $CURRENT_HEADER_FONT): " HEADER_FONT_SIZE

# Update Alacritty font size
sed -i "s/size = .*/size = $TERM_FONT_SIZE/" ~/.config/alacritty/alacritty.toml
echo "✅ Terminal font updated to $TERM_FONT_SIZE"

# Update Rofi font size
sed -i "s/font: \".*\";/font: \"RobotoMono Nerd Font $ROFI_FONT_SIZE\";/" ~/.config/rofi/config.rasi
echo "✅ CMD+D Popup font updated to $ROFI_FONT_SIZE"

# Update i3 header font size
sed -i "s/font pango:.*/font pango:RobotoMono Nerd Font Regular $HEADER_FONT_SIZE/" ~/.config/i3/config
echo "✅ i3 Header font updated to $HEADER_FONT_SIZE"

# Set Firefox scaling
FIREFOX_PROFILE=$(find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.default-release" | head -n 1)
if [[ -z "$FIREFOX_PROFILE" ]]; then
    FIREFOX_PROFILE=$(find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.default" | head -n 1)
fi

if [[ -d "$FIREFOX_PROFILE" ]]; then
    echo "✅ Found Firefox profile: $FIREFOX_PROFILE"
    echo "Setting Firefox scaling to $SCALING_FACTOR"

    # Ensure Firefox is not running
   # Gracefully close Firefox
    if pgrep firefox > /dev/null; then
        killall -TERM firefox
        sleep 2
    fi

    # Update user.js (persistent setting)
    echo "user_pref(\"layout.css.devPixelsPerPx\", \"$SCALING_FACTOR\");" > "$FIREFOX_PROFILE/user.js"

    # Ensure prefs.js gets updated
    if [[ -f "$FIREFOX_PROFILE/prefs.js" ]]; then
        cp "$FIREFOX_PROFILE/prefs.js" "$FIREFOX_PROFILE/prefs.js.bak"
        sed -i "/layout.css.devPixelsPerPx/d" "$FIREFOX_PROFILE/prefs.js"
        echo "user_pref(\"layout.css.devPixelsPerPx\", \"$SCALING_FACTOR\");" >> "$FIREFOX_PROFILE/prefs.js"
    else
        echo "⚠️ Firefox prefs.js not found. Launching Firefox to generate it..."
        firefox &
        sleep 5
        pkill firefox
    fi

    # Restart Firefox after ensuring no zombie processes
    firefox --no-remote &
    disown
    echo "🔥 Firefox scaling updated. Restarting Firefox..."
else
    echo "⚠️ No Firefox profile found! Is Firefox installed?"
fi

# Fix Electron apps (Visual Studio Code)
export ELECTRON_FORCE_DEVICE_SCALE_FACTOR=$SCALING_FACTOR

# Ensure VS Code config folder exists
mkdir -p ~/.config/Code

# Check if jq is installed, and prompt installation if missing
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is not installed. Install it with:"
    echo "    sudo apt install jq -y"
    exit 1
fi

# Check if argv.json already exists
if [[ -f ~/.config/Code/argv.json ]]; then
    # Update existing file without overwriting other settings
    jq '. + { "force-device-scale-factor": '$SCALING_FACTOR' }' ~/.config/Code/argv.json > ~/.config/Code/argv.tmp && mv ~/.config/Code/argv.tmp ~/.config/Code/argv.json
else
    # Create new file if it doesn't exist
    echo '{ "force-device-scale-factor": '$SCALING_FACTOR' }' > ~/.config/Code/argv.json
fi

pkill code
code &

# Restart i3
i3-msg reload

# Ask to restart Rofi and Terminal
read -p "Do you want to restart Rofi and Terminal? (y/n) " RESTART_CHOICE
if [[ "$RESTART_CHOICE" == "y" ]]; then
    pkill rofi
    pkill -f alacritty
    alacritty &
    rofi -show drun &
    echo "✅ Rofi and Terminal restarted."
else
    echo "Skipping restart."
fi

echo "✅ All changes applied successfully!"