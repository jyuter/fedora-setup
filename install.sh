#!/bin/bash
set -e

echo ">>> Updating system..."
sudo dnf upgrade -y

echo ">>> Installing essential repositories..."
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager enable fedora-cisco-openh264 || true
sudo dnf install -y \
  https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
  https://packages.microsoft.com/yumrepos/vscode/code-latest-1.94.2-1700707853.el7.x86_64.rpm || true

echo ">>> Installing base utilities..."
sudo dnf install -y git curl wget fastfetch htop tmux vim \
  gnome-tweaks neovim python3-pip unzip eza bpytop timeshift dnfdragora snapd

echo ">>> Fixing snap symlink..."
if [ ! -L /snap ]; then
  sudo ln -s /var/lib/snapd/snap /snap
else
  echo "/snap already exists, skipping link creation."
fi

echo ">>> Setting up Flatpak and Snap..."
sudo dnf install -y flatpak
sudo systemctl enable --now snapd.socket || true

echo ">>> Installing desktop apps..."
sudo dnf install -y firefox code google-chrome-stable || true
sudo snap install ticktick || true

echo ">>> Configuring KDE appearance and widgets..."
kwriteconfig5 --file kdeglobals --group "General" --key "ColorScheme" "Breeze Dark"
kwriteconfig5 --file kdeglobals --group "Icons" --key "Theme" "breeze-dark"

echo ">>> Locking bottom panel and adding widgets..."
cat <<EOF > ~/.config/plasma-org.kde.plasma.desktop-appletsrc
[Containments][1][General]
alignment=bottom
showToolbox=false
formfactor=2
immutability=1
plugin=org.kde.panel
location=4
height=2
locked=true

[Containments][1][Applets][1]
plugin=org.kde.plasma.digitalclock
[Containments][1][Applets][1][Configuration][Appearance]
showDate=true
dateFormat=custom
customDateFormat=ddd dd/MM/yyyy
use24hFormat=2

[Containments][1][Applets][2]
plugin=org.kde.plasma.battery
EOF

echo ">>> Setting locale and keyboard..."
sudo localectl set-locale LANG=en_US.UTF-8
sudo localectl set-x11-keymap us,il
sudo localectl set-keymap us,il
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'il')]"

echo ">>> Setting timezone and time format..."
sudo timedatectl set-timezone Asia/Jerusalem
kwriteconfig5 --file kdeglobals --group "Locale" --key "TimeFormat" "HH:mm"

echo ">>> Inverting touchpad scroll direction..."
kwriteconfig5 --file kcm_touchpadrc --group "Touchpad" --key "NaturalScroll" "true"

echo ">>> Pinning taskbar apps..."
for app in konsole firefox code ticktick; do
  kstart5 --application "$app" || true
done

echo ">>> Done! Please log out and back in for all KDE settings to apply."
