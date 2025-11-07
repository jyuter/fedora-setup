#!/usr/bin/env bash
set -euo pipefail

USERNAME="jyuter"
USERHOME="/home/$USERNAME"

echo "=== Starting Fedora KDE Setup ==="

# --- Hostname ---
[[ "$(hostname)" != "hp-fedora" ]] && hostnamectl set-hostname hp-fedora

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
dnf install -y dnf-automatic dnf-plugins-core

# --- RPM Fusion ---
for repo in free nonfree; do
    if ! dnf repolist | grep -q rpmfusion-$repo; then
        dnf install -y "https://download1.rpmfusion.org/$repo/fedora/rpmfusion-$repo-release-$(rpm -E %fedora).noarch.rpm"
    fi
done

# --- Kernel dev and Razer ---
dnf install -y kernel-devel
if ! dnf repolist | grep -q hardware:/razer; then
    dnf config-manager --add-repo "https://download.opensuse.org/repositories/hardware:/razer/Fedora_$(rpm -E %fedora)/hardware:razer.repo"
fi
dnf install -y openrazer-meta

# --- Enable Flathub ---
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# --- Git & GitHub ---
for pkg in git gh; do
    dnf list installed $pkg &>/dev/null || dnf install -y $pkg
done
sudo -u "$USERNAME" git config --global user.name "Josh Yuter"
sudo -u "$USERNAME" git config --global user.email "jyuter@gmail.com"

# --- Utilities & Shell ---
# Add Fastfetch via COPR instead of Neofetch
dnf copr enable maksimib/fedora-fastfetch -y

UTILS=(zsh util-linux htop fastfetch neovim fzf bat eza ffmpeg cpufetch lsd bpytop speedtest-cli lolcat tmux \
ripgrep zoxide entr mc stow kvantum ksnip ghostty timeshift dnfdragora snapd)
dnf install -y "${UTILS[@]}"
ln -s /var/lib/snapd/snap /snap || true

# --- Fonts ---
FONT_DIR="/usr/local/share/fonts/nerdfonts"
mkdir -p "$FONT_DIR"
cd "$FONT_DIR"
FONTS=(JetBrainsMono Meslo Lekton RobotoMono Mononoki)
for font in "${FONTS[@]}"; do
    [ ! -f "${font}.ttf" ] && wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/${font}.zip" \
        && unzip -o "${font}.zip" && rm -f "${font}.zip"
done
[ ! -f Hack-Regular.ttf ] && wget -q "https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip" \
    && unzip -o Hack-v3.003-ttf.zip && rm -f Hack-v3.003-ttf.zip
fc-cache -v

# --- Powerlevel10k ---
if [ ! -d "$USERHOME/powerlevel10k" ]; then
    sudo -u "$USERNAME" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USERHOME/powerlevel10k"
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
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
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
sudo -u "$USERNAME" mkdir -p "$USERHOME/Pictures/setup"
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

# KDE Plasma setup: panels, widgets, pinned apps
sudo -u "$USERNAME" dbus-launch --exit-with-session qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var desktops = desktops();
for (var i = 0; i < desktops.length; i++) {
    var d = desktops[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file://'$USERHOME'/Pictures/setup/wallpaper.jpg");
}

// --- Bottom Panel ---
var bottomPanel = new Panel;
bottomPanel.location = "bottom";
bottomPanel.alignment = 0;
bottomPanel.height = 0.06;
bottomPanel.locked = true;
bottomPanel.addWidget("org.kde.plasma.appmenu");
var taskManager = bottomPanel.addWidget("org.kde.plasma.taskmanager");
taskManager.writeConfig("favorites", "konsole.desktop,firefox.desktop,com.ticktick.TickTick.desktop,code.desktop");
taskManager.reloadConfig();
bottomPanel.addWidget("org.kde.plasma.systemtray");

// --- Top Panel ---
var topPanel = new Panel;
topPanel.location = "top";
topPanel.height = 0.04;
topPanel.addWidget("org.kde.plasma.digitalclock");
topPanel.addWidget("org.kde.plasma.battery");
'

# Breeze Dark
lookandfeeltool --apply org.kde.breezedark.desktop

# Timezone and 24h clock
timedatectl set-timezone Asia/Jerusalem
gsettings set org.kde.kglobalaccel.khotkeys clock24h true || true

# Hebrew Keyboard
dnf install -y ibus ibus-hspell
localectl set-x11-keymap us,il pc105 "" grp:alt_shift_toggle

# SDDM login & lock screen
sudo cp login.jpg /usr/share/sddm/themes/breeze/
sudo cp lock.jpg /usr/share/sddm/themes/breeze/
sudo sed -i 's|^Current=.*|Current=breeze|' /etc/sddm.conf || true
sudo sed -i 's|^#Background=.*|Background=/usr/share/sddm/themes/breeze/login.jpg|' /etc/sddm.conf || true

# --- Invert touchpad scrolling ---
sudo -u "$USERNAME" bash -c 'cat <<EOF >> ~/.config/kcminputrc
[Touchpad]
InvertScroll=true
EOF'

# Apply immediately if in X11 session
if command -v xinput >/dev/null 2>&1; then
    TOUCHPAD_ID=$(xinput list | grep -i touchpad | grep -o "id=[0-9]\+" | grep -o "[0-9]\+")
    if [ -n "$TOUCHPAD_ID" ]; then
        xinput set-prop $TOUCHPAD_ID "libinput Natural Scrolling Enabled" 1
    fi
fi

echo "✅ Fedora KDE Setup complete!"
