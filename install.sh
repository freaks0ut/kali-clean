#!/bin/bash

# Update and upgrade system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y alacritty wget curl git thunar \
    arandr flameshot arc-theme feh i3blocks i3status i3 i3-wm lxappearance \
    python3-pip rofi unclutter cargo compton papirus-icon-theme imagemagick \
    libxcb-shape0-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev \
    libxcb1-dev libxcb-icccm4-dev libyajl-dev libev-dev libxcb-xkb-dev \
    libxcb-cursor-dev libxkbcommon-dev libxcb-xinerama0-dev libxkbcommon-x11-dev \
    libstartup-notification0-dev libxcb-randr0-dev libxcb-xrm0 libxcb-xrm-dev \
    autoconf meson ninja-build

# Install additional XCB dependencies for i3-gaps
sudo apt install -y libxcb-render-util0-dev libxcb-shape0-dev libxcb-xfixes0-dev

# Download and install Nerd Fonts
mkdir -p ~/.local/share/fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Iosevka.zip
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/RobotoMono.zip
unzip Iosevka.zip -d ~/.local/share/fonts/
unzip RobotoMono.zip -d ~/.local/share/fonts/
fc-cache -fv

# Clone and install i3-gaps
cd ~
git clone https://github.com/Airblader/i3 i3-gaps
cd i3-gaps
meson build
cd build
ninja
sudo ninja install
cd ~

# Install pywal for theme management
pip3 install --user pywal

# Create config directories and copy configuration files
mkdir -p ~/.config/i3 ~/.config/compton ~/.config/rofi ~/.config/alacritty
cp .config/i3/config ~/.config/i3/config
cp .config/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml
cp .config/i3/i3blocks.conf ~/.config/i3/i3blocks.conf
cp .config/compton/compton.conf ~/.config/compton/compton.conf
cp .config/rofi/config ~/.config/rofi/config
cp .fehbg ~/.fehbg
cp .config/i3/clipboard_fix.sh ~/.config/i3/clipboard_fix.sh
cp -r .wallpaper ~/.wallpaper

# Apply wallpaper settings and set theme
feh --bg-scale ~/.wallpaper/default.jpg
lxappearance --set arc-dark

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Completion message
echo "Installation complete! Reboot and select i3 from the login screen."
