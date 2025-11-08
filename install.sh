#!/usr/bin/env bash
set -e

# --- Simple progress function ---
progress() {
  echo
  echo "=================================================================="
  echo ">>> $1"
  echo "=================================================================="
}

# --- System update ---
progress "Updating system..."
sudo dnf -y update --refresh

# --- Base utilities ---
progress "Installing base utilities..."
sudo dnf -y install \
  git curl wget fastfetch htop tmux neovim unzip \
  timeshift dnfdragora snapd \
  --skip-unavailable

# --- Enable snap + flatpak ---
progress "Configuring snap and flatpak..."
sudo ln -sf /var/lib/snapd/snap /snap || true
sudo dnf -y install flatpak --skip-unavailable
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# --- GUI Apps ---
progress "Installing desktop applications (Flatpak)..."
flatpak install -y flathub com.ticktick.TickTick || true
flatpak install -y flathub org.gimp.GIMP || true
flatpak install -y flathub org.mozilla.firefox || true
flatpak install -y flathub org.videolan.VLC || true
flatpak install -y flathub org.libreoffice.LibreOffice || true
flatpak install -y flathub com.spotify.Client || true
flatpak install -y flathub com.discordapp.Discord || true

# --- VSCode (fixed repo for Fedora) ---
progress "Installing Visual Studio Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo tee /etc/yum.repos.d/vscode.repo > /dev/null << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

if ! sudo dnf -y install code --skip-unavailable; then
  echo "⚠️ VSCode repo temporarily unavailable. Skipping..."
fi

# --- Modern CLI tools ---
progress "Installing modern CLI tools..."
sudo dnf -y install eza btop bat fd-find ripgrep fzf zoxide \
  --skip-unavailable || {
    echo "⚠️ Some modern CLI tools unavailable. Skipping..."
  }

# --- Developer tools ---
progress "Installing developer tools..."
sudo dnf -y groupinstall "Development Tools" --skip-unavailable
sudo dnf -y install nodejs python3-pip dotnet-sdk \
  --skip-unavailable || true

# --- Timeshift auto snapshots ---
progress "Enabling Timeshift auto snapshots..."
sudo systemctl enable timeshift.timer || true

# --- Final cleanup ---
progress "Cleaning up..."
sudo dnf -y autoremove
sudo dnf clean all

# --- Done ---
progress "✅ Fedora setup complete!"
echo "✨ System is now ready!"
echo "   • Reboot recommended."
echo "   • Launch apps with:"
echo "       TickTick → flatpak run com.ticktick.TickTick"
echo "       VSCode   → code"
echo "       GIMP     → flatpak run org.gimp.GIMP"
echo
