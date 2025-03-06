#!/bin/zsh

# Ensure a scale factor is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <scale_factor>"
    echo "Example: $0 1.5"
    exit 1
fi

SCALE_FACTOR=$1
DPI_SCALE=$(bc <<< "scale=2; 1/$SCALE_FACTOR")

echo "🔍 Debugging GTK scaling issues..."
echo "--------------------------------"

### ✅ Step 1: Find and Fix Conflicting GDK_SCALE Values

# Check ~/.profile
PROFILE_FILE="$HOME/.profile"
if grep -q "export GDK_SCALE=" "$PROFILE_FILE"; then
    echo "⚠️ Removing conflicting GDK_SCALE from ~/.profile..."
    sed -i '/export GDK_SCALE=/d' "$PROFILE_FILE"
fi

if grep -q "export GDK_DPI_SCALE=" "$PROFILE_FILE"; then
    echo "⚠️ Removing conflicting GDK_DPI_SCALE from ~/.profile..."
    sed -i '/export GDK_DPI_SCALE=/d' "$PROFILE_FILE"
fi

# Check ~/.xsessionrc
XSESSIONRC_FILE="$HOME/.xsessionrc"
if grep -q "export GDK_SCALE=" "$XSESSIONRC_FILE"; then
    echo "⚠️ Removing old GDK_SCALE from ~/.xsessionrc..."
    sed -i '/export GDK_SCALE=/d' "$XSESSIONRC_FILE"
fi

if grep -q "export GDK_DPI_SCALE=" "$XSESSIONRC_FILE"; then
    echo "⚠️ Removing old GDK_DPI_SCALE from ~/.xsessionrc..."
    sed -i '/export GDK_DPI_SCALE=/d' "$XSESSIONRC_FILE"
fi

# Set the correct values in ~/.xsessionrc
echo "✅ Writing new GTK scaling values..."
echo "export GDK_SCALE=$SCALE_FACTOR" >> "$XSESSIONRC_FILE"
echo "export GDK_DPI_SCALE=$DPI_SCALE" >> "$XSESSIONRC_FILE"

# Ensure ~/.xinitrc loads ~/.xsessionrc
XINITRC_FILE="$HOME/.xinitrc"
if ! grep -q "source ~/.xsessionrc" "$XINITRC_FILE"; then
    echo "🔄 Adding source command to ~/.xinitrc..."
    echo "source ~/.xsessionrc" >> "$XINITRC_FILE"
fi

### ✅ Step 2: Apply Changes Immediately

echo "🚀 Applying scaling now..."
export GDK_SCALE=$SCALE_FACTOR
export GDK_DPI_SCALE=$DPI_SCALE
source "$XSESSIONRC_FILE"

### ✅ Step 3: Restart i3 to Apply System-Wide

echo "🔄 Restarting i3..."
i3-msg restart

### ✅ Step 4: Check for System-Wide Overrides

echo "🔍 Checking for global overrides in /etc/..."
GLOBAL_OVERRIDES=$(grep -rn "GDK_SCALE" /etc/ 2>/dev/null)
if [ -n "$GLOBAL_OVERRIDES" ]; then
    echo "⚠️ Found system-wide overrides:"
    echo "$GLOBAL_OVERRIDES"
    echo "You may need to manually remove them from the listed files."
else
    echo "✅ No system-wide overrides found."
fi

### ✅ Final Check
echo "--------------------------------"
echo "🔎 Final Debug Info:"
echo "GDK_SCALE: $GDK_SCALE"
echo "GDK_DPI_SCALE: $GDK_DPI_SCALE"
echo "--------------------------------"
echo "🎉 Scaling should now be fixed! Reboot and verify."

