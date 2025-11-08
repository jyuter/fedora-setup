#!/usr/bin/env bash
set -e

echo ">>> Fedora setup script starting..."
sudo -v

### --- Update system ---
echo ">>> Updating system packages..."
sudo dnf upgrade --refresh -y

### --- Enable RPM Fusion (Free + Non-Free) ---
echo ">>> Enabling RPM Fusion..."
sudo dnf install -y \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

### --- Enable Flathub ---
echo ">>> Adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

### --- Base tools ---
echo ">>> Installing essential packages..."
sudo dnf install -y \
  git curl wget unzip neovim tmux htop fastfetch timeshift dnfdragora snapd \
  ffmpeg-free --skip-broken --allowerasing || true

# Handle symbolic link for snap (ignore if exists)
sudo ln -sf /var/lib/snapd/snap /snap || true

### --- Fix for missing utilities ---
# bpytop renamed → btop; eza may not exist, fallback to exa
sudo dnf install -y btop exa || true

### --- VSCode (Microsoft repo fix) ---
echo ">>> Setting up Visual Studio Code repository..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | \
  sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
sudo dnf check-update || true
sudo dnf install -y code || true

### --- Browsers ---
echo ">>> Installing Google Chrome..."
sudo dnf install -y fedora-workstation-repositories
sudo dnf config-manager --set-enabled google-chrome || true
sudo dnf install -y google-chrome-stable --skip-unavailable || true

### --- Flatpak apps ---
echo ">>> Installing Flatpak apps..."
flatpak install -y flathub com.ticktick.TickTick
flatpak install -y flathub org.mozilla.firefox
flatpak install -y flathub org.gimp.GIMP || true

### --- Create desktop shortcuts for Flatpak apps ---
echo ">>> Ensuring Flatpak apps appear in the application menu..."
sudo update-desktop-database /usr/share/applications || true

### --- Invert touchpad scrolling ---
echo ">>> Inverting touchpad scrolling..."
TOUCHPAD_CONF="/etc/X11/xorg.conf.d/40-libinput.conf"
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee $TOUCHPAD_CONF > /dev/null <<'EOF'
Section "InputClass"
    Identifier "touchpad catchall"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "NaturalScrolling" "true"
EndSection
EOF

### --- Pin apps to taskbar (GNOME) ---
echo ">>> Pinning favorite apps to GNOME dock..."
gsettings set org.gnome.shell favorite-apps "[
  'org.gnome.Terminal.desktop',
  'firefox.desktop',
  'com.ticktick.TickTick.desktop',
  'code.desktop'
]"

### --- Cleanup ---
echo ">>> Cleaning up unused packages..."
sudo dnf autoremove -y
sudo dnf clean all

### --- Final message ---
echo ">>> ✅ Setup complete! Please reboot for all changes to take effect."
