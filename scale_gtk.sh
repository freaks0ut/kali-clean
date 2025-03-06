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

# Adjust DPI scale (GTK apps work better when DPI is adjusted)
DPI_SCALE=$(bc <<< "scale=2; 1/$SCALE_FACTOR")

echo "Applying GTK scaling persistently..."

### ✅ Apply settings for current session ###
export GDK_SCALE=$SCALE_FACTOR
export GDK_DPI_SCALE=$DPI_SCALE

# Apply Xresources (just in case)
xrdb -merge ~/.Xresources

# Apply changes to ~/.xsessionrc to persist on every reboot
XSESSIONRC="$HOME/.xsessionrc"
if ! grep -q "export GDK_SCALE=" "$XSESSIONRC"; then
    echo "export GDK_SCALE=$SCALE_FACTOR" >> "$XSESSIONRC"
    echo "export GDK_DPI_SCALE=$DPI_SCALE" >> "$XSESSIONRC"
else
    sed -i "s|^export GDK_SCALE=.*|export GDK_SCALE=$SCALE_FACTOR|" "$XSESSIONRC"
    sed -i "s|^export GDK_DPI_SCALE=.*|export GDK_DPI_SCALE=$DPI_SCALE|" "$XSESSIONRC"
fi
echo "Persisted GTK scaling in $XSESSIONRC."

# Restart i3 to apply settings system-wide
echo "Restarting i3..."
i3-msg restart

echo "GTK applications are now scaled. Restart apps to see the effect!"

