#!/usr/bin/env bash
set -euo pipefail

USERNAME="jyuter"
USERHOME="/home/$USERNAME"

echo "=== Starting Fedora KDE Setup ==="

# --- Hostname ---
hostnamectl set-hostname hp-fedora

# --- DNF config ---
DNF_CONF="/etc/dnf/dnf.conf"
if ! grep -q "fastestmirror=True" "$DNF_CONF"; then
    cat <<EOF >/etc/dnf/dnf.conf
[main]
fastestmirror=True
max_parallel_downloads=10
defaultyes=True
keepcache=True
EOF
fi

# --- Update system ---
dnf upgrade --refresh -y
dnf install -y dnf-automatic dnf-plugins-core wget unzip

# --- Enable Flathub ---
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# --- Install core packages ---
CORE_PKGS=(git gh zsh util-linux htop fastfetch neovim fzf bat eza ffmpeg cpufetch lsd bpytop \
speedtest-cli lolcat tmux ripgrep zoxide entr mc stow kvantum ksnip ghostty timeshift dnfdragora snapd)
dnf install -y "${CORE_PKGS[@]}"
ln -s /var/lib/snapd/snap /snap || true

# --- Git configuration as user (fixed PATH issue) ---
sudo -i -u "$USERNAME" env PATH=$PATH bash <<'EOF'
git config --global user.name "Josh Yuter"
git config --global user.email "jyuter@gmail.com"
EOF

# --- Fonts ---
FONT_DIR="/usr/local/share/fonts/nerdfonts"
mkdir -p "$FONT_DIR"
cd "$FONT_DIR"

FONTS=(JetBrainsMono Meslo Lekton RobotoMono Mononoki)
for font in "${FONTS[@]}"; do
    [ ! -f "${font}.zip" ] && wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/${font}.zip"
    unzip -o "${font}.zip"
    rm -f "${font}.zip"
done

# Hack font
[ ! -f Hack-v3.003-ttf.zip ] && wget -q "https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip"
unzip -o Hack-v3.003-ttf.zip
rm -f Hack-v3.003-ttf.zip

fc-cache -v

# --- Powerlevel10k ---
if [ ! -d "$USERHOME/powerlevel10k" ]; then
    sudo -i -u "$USERNAME" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USERHOME/powerlevel10k"
    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> "$USERHOME/.zshrc"
    chown -R "$USERNAME":"$USERNAME" "$USERHOME/powerlevel10k" "$USERHOME/.zshrc"
fi

# --- Development tools ---
DEV_PKGS=(dotnet-sdk-8.0 gcc elixir php-cli phpunit composer php-pdo php-pdo_mysql erlang redis rabbitmq-server nginx ruby rustup golang nodejs)
dnf install -y "${DEV_PKGS[@]}"
systemctl enable redis nginx
systemctl start nginx
firewall-cmd --permanent --add-service={http,https}
firewall-cmd --reload

# --- Containers ---
dnf install -y podman
DOCKER_REPO="/etc/yum.repos.d/docker-ce.repo"
if [ ! -f "$DOCKER_REPO" ]; then
    wget -q https://download.docker.com/linux/fedora/docker-ce.repo -O "$DOCKER_REPO"
fi
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
wget -q -O docker-desktop.rpm "https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm"
dnf install -y ./docker-desktop.rpm && rm -f ./docker-desktop.rpm
systemctl enable --now docker

# --- Editors & Browsers ---
dnf install -y code firefox google-chrome-stable brave-browser
snap install bruno postman

# --- Media ---
dnf swap ffmpeg-free ffmpeg --allowerasing -y
dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
dnf update @sound-and-video -y
dnf install -y intel-media-driver vlc mpv
dnf group install -y Multimedia

# --- Flatpaks ---
FLATPAKS=(org.zotero.Zotero com.bitwarden.desktop io.github.giantpinkrobots.flatsweep com.github.dail8859.NotepadNext com.ticktick.TickTick com.github.PintaProject.Pinta)
for app in "${FLATPAKS[@]}"; do
    flatpak install -y flathub "$app"
done

# --- KDE Personalization ---
sudo -i -u "$USERNAME" mkdir -p "$USERHOME/Pictures/setup"
cd "$USERHOME/Pictures/setup"

IMG_URLS=(
"https://github.com/jyuter/fedora-setup/raw/main/images/Profile-Podcast.png:user.png"
"https://github.com/jyuter/fedora-setup/raw/main/images/hamlet.jpg:wallpaper.jpg"
"https://github.com/jyuter/fedora-setup/raw/main/images/northern-lights.jpg:login.jpg"
"https://github.com/jyuter/fedora-setup/raw/main/images/mountain-purple.jpg:lock.jpg"
)
for pair in "${IMG_URLS[@]}"; do
    url="${pair%%:*}"
    file="${pair##*:}"
    [ ! -f "$file" ] && wget -q "$url" -O "$file"
done

# User photo
cp user.png /var/lib/AccountsService/icons/$USERNAME.png
cat <<EOF >/var/lib/AccountsService/users/$USERNAME
[User]
Icon=/var/lib/AccountsService/icons/$USERNAME.png
EOF

# --- KDE Plasma panels and widgets ---
sudo -i -u "$USERNAME" dbus-launch --exit-with-session qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var desktops = desktops();
for (var i = 0; i < desktops.length; i++) {
    var d = desktops[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file://'$USERHOME'/Pictures/setup/wallpaper.jpg");
}

// Bottom panel
var bottomPanel = new Panel;
bottomPanel.location = "bottom";
bottomPanel.alignment = 0;
bottomPanel.height = 0.06;
bottomPanel.locked = true;
var taskManager = bottomPanel.addWidget("org.kde.plasma.taskmanager");
taskManager.writeConfig("favorites", "konsole.desktop,firefox.desktop,com.ticktick.TickTick.desktop,code.desktop");
taskManager.reloadConfig();

// Top panel
var topPanel = new Panel;
topPanel.location = "top";
topPanel.height = 0.04;
var clock = topPanel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
topPanel.addWidget("org.kde.plasma.battery");
'

lookandfeeltool --apply org.kde.breezedark.desktop
timedatectl set-timezone Asia/Jerusalem

# Hebrew keyboard with flag icon
dnf install -y ibus ibus-hspell
localectl set-x11-keymap us,il pc105 "" grp:alt_shift_toggle

# SDDM login & lock screen
sudo cp login.jpg /usr/share/sddm/themes/breeze/
sudo cp lock.jpg /usr/share/sddm/themes/breeze/
sudo sed -i 's|^Current=.*|Current=breeze|' /etc/sddm.conf || true
sudo sed -i 's|^#Background=.*|Background=/usr/share/sddm/themes/breeze/login.jpg|' /etc/sddm.conf || true

# --- Invert touchpad scrolling ---
sudo -i -u "$USERNAME" bash <<EOF
mkdir -p ~/.config
cat <<EOT >> ~/.config/kcminputrc
[Touchpad]
InvertScroll=true
EOT
EOF

# --- Check if kernel upgrade requires reboot ---
if [ -f /var/run/reboot-required ] || [ "$(needs-restarting -r 2>/dev/null)" == "1" ]; then
    echo "Kernel or DKMS requires reboot. Rebooting now..."
    systemctl reboot
fi

echo "✅ Fedora KDE Setup complete!"
