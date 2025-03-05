#!/bin/bash

# Get current values
CURRENT_DPI=$(xrdb -query | grep Xft.dpi | awk '{print $2}')
CURRENT_TERM_FONT=$(grep -m1 'size =' ~/.config/alacritty/alacritty.toml | awk '{print $3}')
CURRENT_ROFI_FONT=$(grep -oP 'font:\s*"\K[^"]+' ~/.config/rofi/config.rasi)
CURRENT_HEADER_FONT=$(grep -m1 'font pango:' ~/.config/i3/config | awk -F ' ' '{print $(NF)}')

# Prompt user for new values
echo "Enter DPI (recommended: 192 for MacBook, current: $CURRENT_DPI):"
read DPI

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

# Apply DPI
echo "Xft.dpi: $DPI" | xrdb -merge

# ✅ Correctly update Alacritty font size (fixes TOML formatting)
sed -i 's/^\(size =\) [0-9]\+/\1 '"$TERM_FONT_SIZE"'/' ~/.config/alacritty/alacritty.toml

# ✅ Ensure Rofi font is correctly formatted in `config.rasi`
if grep -q 'font:' ~/.config/rofi/config.rasi; then
    sed -i 's|font: ".*"|font: "RobotoMono Nerd Font '"$ROFI_FONT_SIZE"'"|g' ~/.config/rofi/config.rasi
else
    echo -e '\nfont: "RobotoMono Nerd Font '"$ROFI_FONT_SIZE"'";' >> ~/.config/rofi/config.rasi
fi

# ✅ Ensure Rofi `config.rasi` has correct bracket structure
ROFI_BRACKET_COUNT=$(grep -o '{' ~/.config/rofi/config.rasi | wc -l)
ROFI_CLOSING_BRACKET_COUNT=$(grep -o '}' ~/.config/rofi/config.rasi | wc -l)

if [[ "$ROFI_BRACKET_COUNT" -ne "$ROFI_CLOSING_BRACKET_COUNT" ]]; then
    echo "Fixing Rofi config: adding missing closing bracket..."
    echo "}" >> ~/.config/rofi/config.rasi
fi

# ✅ Ensure i3 uses the correct Rofi command with the updated config
if ! grep -q "rofi -show drun -config ~/.config/rofi/config.rasi" ~/.config/i3/config; then
    sed -i "s|rofi -show drun|rofi -show drun -config ~/.config/rofi/config.rasi|" ~/.config/i3/config
fi

# ✅ Update i3 Header Font
sed -i 's/font pango:.* [0-9]\+/font pango:RobotoMono Nerd Font Regular '"$HEADER_FONT_SIZE"'/' ~/.config/i3/config

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