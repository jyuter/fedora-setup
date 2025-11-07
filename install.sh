#!/usr/bin/env bash
set -euo pipefail

USERNAME="jyuter"
USERHOME="/home/$USERNAME"

echo "=== Starting Fedora KDE Setup ==="

# --- Hostname ---
if [[ "$(hostname)" != "hp-fedora" ]]; then
    hostnamectl set-hostname hp-fedora
    echo "Hostname set to hp-fedora"
fi

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
    echo "Updated dnf.conf"
fi

# --- System update ---
echo "Updating system..."
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
if ! flatpak remotes | grep -q flathub; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

# --- Git & GitHub ---
for pkg in git gh; do
    if ! dnf list installed $pkg &>/dev/null; then
        dnf install -y $pkg
    fi
done
sudo -u "$USERNAME" git config --global user.name "Josh Yuter"
sudo -u "$USERNAME" git config --global user.email "jyuter@gmail.com"

# --- Shell & Utilities ---
UTILS=(zsh util-linux htop neofetch neovim fzf bat eza ffmpeg bpytop speedtest-cli lolcat tmux \
ripgrep zoxide entr mc stow kvantum ksnip ghostty timeshift dnfdragora snapd)
dnf install -y "${UTILS[@]}"
ln -s /var/lib/snapd/snap /snap || true

# --- Fonts ---
FONT_DIR="/usr/local/share/fonts/nerdfonts"
mkdir -p "$FONT_DIR"
cd "$FONT_DIR"
declare -a FONTS=("JetBrainsMono" "Meslo" "Lekton" "RobotoMono" "Mononoki")
for font in "${FONTS[@]}"; do
    if [ ! -f "$FONT_DIR/${font}.ttf" ]; then
        wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/${font}.zip"
        unzip -o "${font}.zip"
        rm -f "${font}.zip"
    fi
done
if [ ! -f "$FONT_DIR/Hack-Regular.ttf" ]; then
    wget -q "https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip"
    unzip -o Hack-v3.003-ttf.zip
    rm -f Hack-v3.003-ttf.zip
fi
fc-cache -v

# --- Powerlevel10k ---
if [ ! -d "$USERHOME/powerlevel10k" ]; then
    sudo -u "$USERNAME" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USERHOME/powerlevel10k"
    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> "$USERHOME/.zshrc"
    chown -R "$USERNAME":"$USERNAME" "$USERHOME/powerlevel10k" "$USERHOME/.zshrc"
fi

# --- Dev Tools ---
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
if [ ! -f "./docker-desktop.rpm" ]; then
    wget -q -O docker-desktop.rpm "https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm"
    dnf install -y ./docker-desktop.rpm && rm -f ./docker-desktop.rpm
fi
systemctl enable --now docker

# --- Editors & API testing ---
dnf install -y code
snap install bruno
snap install postman

# --- Browsers ---
dnf install -y fedora-workstation-repositories
dnf config-manager --set-enabled google-chrome
dnf install -y google-chrome-stable
dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
dnf install -y brave-browser

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

# --- KDE personalization ---
echo "Applying wallpapers, lock/login, and user photo..."
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
    if [ ! -f "$file" ]; then
        wget -q "$url" -O "$file"
    fi
done

# User account photo
cp user.png /var/lib/AccountsService/icons/$USERNAME.png
cat <<EOF >/var/lib/AccountsService/users/$USERNAME
[User]
Icon=/var/lib/AccountsService/icons/$USERNAME.png
EOF

# Desktop wallpaper & panel
sudo -u "$USERNAME" dbus-launch --exit-with-session bash -c "
  plasma-apply-wallpaperimage $USERHOME/Pictures/setup/wallpaper.jpg
  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    var allDesktops = desktops();
    for (i=0; i<allDesktops.length; i++) {
      d = allDesktops[i];
      d.wallpaperPlugin = \"org.kde.image\";
      d.currentConfigGroup = [\"Wallpaper\", \"org.kde.image\", \"General\"];
      d.writeConfig(\"Image\", \"file://$USERHOME/Pictures/setup/wallpaper.jpg\");
    }'
"

# Panels/widgets (basic example)
sudo -u "$USERNAME" dbus-launch --exit-with-session qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var panel = new Panel;
panel.location = "bottom";
panel.addWidget("org.kde.plasma.taskmanager");
panel.addWidget("org.kde.plasma.digitalclock");
'

# SDDM login & lock screens
sudo cp login.jpg /usr/share/sddm/themes/breeze/
sudo cp lock.jpg /usr/share/sddm/themes/breeze/
sudo sed -i 's|^Current=.*|Current=breeze|' /etc/sddm.conf || true
sudo sed -i 's|^#Background=.*|Background=/usr/share/sddm/themes/breeze/login.jpg|' /etc/sddm.conf || true

echo "✅ Fedora KDE Setup complete!"
