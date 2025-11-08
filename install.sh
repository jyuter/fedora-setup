#!/bin/bash
set -e

echo ">>> Updating system..."
sudo dnf upgrade -y

echo ">>> Enabling additional repositories..."
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager enable fedora-cisco-openh264 || true
sudo dnf copr enable atim/eza -y || true

# Add Microsoft repo for VSCode
if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
fi

# Add Google Chrome repo
if [ ! -f /etc/yum.repos.d/google-chrome.repo ]; then
  sudo sh -c 'echo -e "[google-chrome]\nname=Google Chrome\nbaseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64\nenabled=1\ngpgcheck=1\ngpgkey=https://dl.google.com/linux/linux_signing_key.pub" > /etc/yum.repos.d/google-chrome.repo'
fi

echo ">>> Installing base utilities..."
sudo dnf install -y git curl wget fastfetch htop tmux vim \
  neovim python3-pip unzip eza btop timeshift dnfdragora snapd || true

echo ">>> Fixing snap symlink..."
if [ ! -L /snap ]; then
  sudo ln -s /var/lib/snapd/snap /snap
else
  echo "/snap already exists, skipping link creation."
fi

echo ">>> Setting up Flatpak..."
sudo dnf install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo ">>> Installing desktop apps..."
sudo dnf install -y firefox code google-chrome-stable || true
flatpak install -y flathub com.ticktick.TickTick

echo ">>> Configuring KDE appearance and widgets..."
kwriteconfig5 --file kdeglobals --group "General" --key "ColorScheme" "Breeze Dark"
kwriteconfig5 --file kdeglobals --group "Icons" --key "Theme" "breeze-dark"

echo ">>> Locking bottom panel and adding widgets..."
mkdir -p ~/.config
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

echo ">>> Setting locale, keyboard, and region..."
sudo localectl set-locale LANG=en_US.UTF-8
sudo localectl set-x11-keymap us,il
sudo localectl set-keymap us,il
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'il')]"
sudo timedatectl set-timezone Asia/Jerusalem
kwriteconfig5 --file kdeglobals --group "Locale" --key "TimeFormat" "HH:mm"

echo ">>> Inverting touchpad scroll direction..."
kwriteconfig5 --file kcm_touchpadrc --group "Touchpad" --key "NaturalScroll" "true"

echo ">>> Pinning taskbar apps..."
for app in konsole firefox code ticktick; do
  kstart5 --application "$app" || true
done

echo ">>> Setup complete!"
echo "Please log out and back in for all KDE settings to take effect."
