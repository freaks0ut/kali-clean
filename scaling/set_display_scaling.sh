#!/bin/bash

export DISPLAY=:0
sleep 3  # Ensure display is fully loaded

# Get current values
CURRENT_DPI=$(xrdb -query | grep Xft.dpi | awk '{print $2}')
CURRENT_TERM_FONT=$(grep -m1 'size =' ~/.config/alacritty/alacritty.toml | awk '{print $3}')
CURRENT_ROFI_FONT=$(grep -oP 'font:\s*"\K[^"]+' ~/.config/rofi/config.rasi)
CURRENT_HEADER_FONT=$(grep -m1 'font pango:' ~/.config/i3/config | awk -F ' ' '{print $(NF)}')
CURRENT_SCREEN_RES=$(xrandr | grep '*' | awk '{print $1}')

# Ask user to choose between resolutions
echo "Choose screen resolution:"
echo "0: MacBook 14'' default resolution (3024x1964)"
echo "1: 2560x1440 (for external displays)"
read -p "Enter 0 or 1: " RESOLUTION_OPTION

if [[ "$RESOLUTION_OPTION" == "0" ]]; then
    NEW_RESOLUTION="3024x1964"
    DPI=192
elif [[ "$RESOLUTION_OPTION" == "1" ]]; then
    NEW_RESOLUTION="2560x1440_60.00"
    DPI=144
else
    echo "Invalid option. Exiting."
    exit 1
fi

# Prompt user for font sizes
echo "Enter Terminal Font Size (recommended: 16-18, current: $CURRENT_TERM_FONT):"
read TERM_FONT_SIZE

if [[ "$TERM_FONT_SIZE" -lt 10 || "$TERM_FONT_SIZE" -gt 30 ]]; then
    echo "Error: Terminal font size should be between 10 and 30."
    exit 1
fi

echo "Enter CMD+D Popup Font Size (recommended: 14-16, current: $CURRENT_ROFI_FONT):"
read ROFI_FONT_SIZE

if [[ "$ROFI_FONT_SIZE" -lt 10 || "$ROFI_FONT_SIZE" -gt 30 ]]; then
    echo "Error: Rofi font size should be between 10 and 30."
    exit 1
fi

echo "Enter i3 Header Font Size (recommended: 14-16, current: $CURRENT_HEADER_FONT):"
read HEADER_FONT_SIZE

# ✅ Ask for scaling factor
echo "Enter scaling factor for applications (recommended: 1.5 for 2560x1440, 2.0 for MacBook default):"
read SCALING_FACTOR

# Apply DPI
echo "Xft.dpi: $DPI" | xrdb -merge

# ✅ Update Alacritty font size
sed -i 's/^\(size =\) [0-9]\+/\1 '"$TERM_FONT_SIZE"'/' ~/.config/alacritty/alacritty.toml

# ✅ Ensure Rofi font is correctly formatted in `config.rasi`
if grep -q 'font:' ~/.config/rofi/config.rasi; then
    sed -i 's|font: ".*"|font: "RobotoMono Nerd Font '"$ROFI_FONT_SIZE"'"|g' ~/.config/rofi/config.rasi
else
    echo -e '\nfont: "RobotoMono Nerd Font '"$ROFI_FONT_SIZE"'";' >> ~/.config/rofi/config.rasi
fi

# ✅ Ensure i3 uses the correct Rofi command with updated config
if ! grep -q "rofi -show drun -config ~/.config/rofi/config.rasi" ~/.config/i3/config; then
    sed -i "s|rofi -show drun|rofi -show drun -config ~/.config/rofi/config.rasi|" ~/.config/i3/config
fi

# ✅ Update i3 Header Font
sed -i 's/font pango:.* [0-9]\+/font pango:RobotoMono Nerd Font Regular '"$HEADER_FONT_SIZE"'/' ~/.config/i3/config

# ✅ Fix xrandr resolution (Create it if missing)
AVAILABLE_MODES=$(xrandr | awk '{print $1}' | grep -E "^[0-9]+x[0-9]+$")
if ! echo "$AVAILABLE_MODES" | grep -q "$NEW_RESOLUTION"; then
    echo "Creating new resolution: $NEW_RESOLUTION"
    if [[ "$NEW_RESOLUTION" == "2560x1440_60.00" ]]; then
        xrandr --newmode "2560x1440_60.00"  241.50  2560 2720 2992 3424  1440 1443 1448 1481 -hsync +vsync
        xrandr --addmode Virtual-1 "2560x1440_60.00"
    elif [[ "$NEW_RESOLUTION" == "3024x1964" ]]; then
        xrandr --newmode "3024x1964_60.00"  358.25  3024 3288 3624 4224  1964 1967 1977 2017 -hsync +vsync
        xrandr --addmode Virtual-1 "3024x1964_60.00"
    fi
fi
xrandr --output Virtual-1 --mode "$NEW_RESOLUTION"

# ✅ Apply scaling for all graphical applications
echo "Applying scaling for graphical applications..."
gsettings set org.gnome.desktop.interface text-scaling-factor "$SCALING_FACTOR"
gsettings set org.gnome.desktop.interface scaling-factor 2
gsettings set org.gnome.desktop.interface cursor-size 48

# ✅ Apply Firefox-specific scaling
FIREFOX_PROFILE=$(find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.default*" | head -n 1)
if [[ -d "$FIREFOX_PROFILE" ]]; then
    echo "user_pref(\"layout.css.devPixelsPerPx\", \"$SCALING_FACTOR\");" > "$FIREFOX_PROFILE/user.js"
fi

# ✅ Apply Chrome/Chromium scaling
if [ -f ~/.config/chromium/Default/Preferences ]; then
    sed -i 's/"devtools":{"zoom":"[0-9]\+\.[0-9]\+"}/"devtools":{"zoom":"'"$SCALING_FACTOR"'"}' ~/.config/chromium/Default/Preferences
fi

# Reload i3 to apply changes
i3-msg reload

# Restart applications if requested
echo "Do you want to restart Rofi and Terminal? (y/n)"
read RESTART_CHOICE
if [[ "$RESTART_CHOICE" == "y" ]]; then
    pkill rofi
    pkill -f alacritty
    alacritty &
    rofi -show drun -config ~/.config/rofi/config.rasi &
    echo "Rofi and Terminal restarted."
else
    echo "Skipping restart."
fi

echo "Changes applied successfully!"