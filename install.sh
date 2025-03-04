#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install core utilities
sudo apt install -y wget curl git thunar 

# Install i3 and related tools
sudo apt install -y \
  alacritty arandr flameshot arc-theme feh \
  i3blocks i3status i3 i3-wm lxappearance \
  rofi unclutter cargo compton papirus-icon-theme imagemagick

# Install dependencies for i3-gaps
sudo apt install -y \
  libxcb-shape0-dev libxcb-keysyms1-dev libpango1.0-dev \
  libxcb-util0-dev libxcb1-dev libxcb-icccm4-dev libyajl-dev \
  libev-dev libxcb-xkb-dev libxcb-cursor-dev libxkbcommon-dev \
  libxcb-xinerama0-dev libxkbcommon-x11-dev libstartup-notification0-dev \
  libxcb-randr0-dev libxcb-xrm0 libxcb-xrm-dev autoconf meson ninja-build \
  libxcb-render-util0-dev libxcb-shape0-dev libxcb-xfixes0-dev build-essential 

# Fix broken dependencies
sudo apt --fix-broken install -y

# Download and install Nerd Fonts
mkdir -p ~/.local/share/fonts/
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Iosevka.zip
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/RobotoMono.zip
unzip -o Iosevka.zip -d ~/.local/share/fonts/
unzip -o RobotoMono.zip -d ~/.local/share/fonts/
fc-cache -fv
rm Iosevka.zip RobotoMono.zip

# Clone and build i3-gaps
git clone https://www.github.com/Airblader/i3 i3-gaps
cd i3-gaps
mkdir -p build && cd build
meson ..
ninja
sudo ninja install
cd ../..
rm -rf i3-gaps

# Install Pywal in a virtual environment (fixes PEP 668 issue)
mkdir -p ~/.venvs
python3 -m venv ~/.venvs/pywal
~/.venvs/pywal/bin/pip install pywal
echo 'export PATH="$HOME/.venvs/pywal/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/.venvs/pywal/bin:$PATH"' >> ~/.zshrc

# Create necessary directories
mkdir -p ~/.config/i3
mkdir -p ~/.config/compton
mkdir -p ~/.config/rofi
mkdir -p ~/.config/alacritty

# Copy configuration files
cp .config/i3/config ~/.config/i3/config
cp .config/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml
cp .config/i3/i3blocks.conf ~/.config/i3/i3blocks.conf
cp .config/compton/compton.conf ~/.config/compton/compton.conf
cp .config/rofi/config ~/.config/rofi/config
cp .fehbg ~/.fehbg
cp .config/i3/clipboard_fix.sh ~/.config/i3/clipboard_fix.sh
cp -r .wallpaper ~/.wallpaper 

# Set wallpaper and color scheme with Pywal
echo "Done! Grab some wallpaper and run:"
echo "  pywal -i filename"
echo "To set your wallpaper on every boot, edit ~/.fehbg"

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

#apply Arc-Dark Theme:
echo '[Settings]
gtk-theme-name="Arc-Dark"' > ~/.config/gtk-3.0/settings.ini
echo 'gtk-theme-name="Arc-Dark"' > ~/.gtkrc-2.0

# Final message
echo "Reboot and select i3 at login. If not already set, run lxappearance and select Arc-Dark theme."
