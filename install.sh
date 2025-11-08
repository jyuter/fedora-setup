#!/usr/bin/env bash
set -e

echo ">>> Fedora KDE setup starting..."
sudo -v

### --- Update system ---
sudo dnf upgrade --refresh -y

### --- Enable RPM Fusion ---
sudo dnf install -y \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

### --- Enable Flathub ---
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

### --- Base packages ---
sudo dnf install -y git curl wget unzip neovim tmux htop fastfetch timeshift dnfdragora snapd \
  ffmpeg-free --skip-broken --allowerasing || true

sudo ln -sf /var/lib/snapd/snap /snap || true
sudo dnf install -y btop exa || true

### --- VSCode ---
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | \
  sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
sudo dnf check-update || true
sudo dnf install -y code || true

### --- Google Chrome ---
sudo dnf install -y fedora-workstation-repositories
sudo dnf config-manager --set-enabled google-chrome || true
sudo dnf install -y google-chrome-stable --skip-unavailable || true

### --- Flatpak apps ---
flatpak install -y --noninteractive flathub com.ticktick.TickTick || true
flatpak install -y --noninteractive flathub org.gnome.GIMP || true

### --- KDE UI Customization ---
KDE_CONFIG="$HOME/.config"
mkdir -p $KDE_CONFIG

# Desktop background
wget -O $HOME/hamlet.jpg https://raw.githubusercontent.com/jyuter/fedora-setup/main/images/hamlet.jpg
cat > $KDE_CONFIG/plasmarc <<'EOF'
[Theme]
name=Breeze-Dark
EOF

cat > $KDE_CONFIG/plasma-org.kde.plasma.desktop-appletsrc <<'EOF'
[Containments][1]
plugin=desktop
wallpaperplugin=image
[Containments][1][Wallpaper][image]
Image=file:///home/$USER/hamlet.jpg
EOF

# Lock screen and login screen
sudo mkdir -p /usr/share/sddm/themes/breeze
sudo wget -O /usr/share/sddm/themes/breeze/lockscreen.jpg https://raw.githubusercontent.com/jyuter/fedora-setup/main/images/mountain-purple.jpg
sudo wget -O /usr/share/sddm/themes/breeze/login.jpg https://raw.githubusercontent.com/jyuter/fedora-setup/main/images/northern-lights.jpg

# Set user account photo
wget -O $HOME/Profile-Podcast.png https://raw.githubusercontent.com/jyuter/fedora-setup/main/images/Profile-Podcast.png
sudo usermod --avatar "$HOME/Profile-Podcast.png" $USER || true

# Taskbar pinned apps
kwriteconfig5 --file $KDE_CONFIG/plasmarc --group 'Taskbar' --key 'Favorites' '["konsole.desktop","firefox.desktop","com.ticktick.TickTick.desktop","code.desktop"]'
kwriteconfig5 --file $KDE_CONFIG/plasmarc --group 'Taskbar' --key 'Locked' true

# Top widget: time/date centered, battery right
kwriteconfig5 --file $KDE_CONFIG/plasmarc --group 'SystemTray' --key 'ShowBattery' true
kwriteconfig5 --file $KDE_CONFIG/plasmarc --group 'SystemTray' --key 'ClockFormat' '24h'

# Hebrew keyboard, show flag
setxkbmap -layout us,il -option grp:alt_shift_toggle
kwriteconfig5 --file $KDE_CONFIG/kxkbrc --group 'Layout' --key 'ShowIndicator' true

# Region/timezone
timedatectl set-timezone Asia/Jerusalem

# Invert touchpad scrolling
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

### --- Cleanup ---
sudo dnf autoremove -y
sudo dnf clean all

echo ">>> ✅ Fedora KDE setup complete!"
