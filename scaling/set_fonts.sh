#!/bin/bash

echo "🎨 Setting font sizes..."

# Get current font sizes
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

# Restart i3
i3-msg reload

echo "✅ All font settings applied successfully!"

