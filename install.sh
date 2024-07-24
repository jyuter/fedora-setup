# Set Server Name
hostnamectl set-hostname hp-fedora

# Init DNF Conf
echo "Updating dnf.conf..."
echo "fastestmirror=True" >> /etc/dnf/dnf.conf
echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
echo "defaultyes=True" >> /etc/dnf/dnf.conf
echo "keepchache=True" >> /etc/dnf/dnf.conf

# Initial Updates
echo "Running initial updates..."
dnf upgrade --refresh -y
dnf groupupdate core -y
dnf install dnf-automatic -y

# Enable RPM Fusion
echo "Enabling RPM Fusion..."
dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y
dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y

# Firmware Updates
# echo "Updating firmware..."
# fwupdmgr refresh --force
# fwupdmgr get-updates
# fwupdmgr update -y

dnf install kernel-devel -y
dnf config-manager --add-repo https://download.opensuse.org/repositories/hardware:/razer/Fedora_$(rpm -E %fedora)/hardware:razer.repo -y
dnf install openrazer-meta -y

# Enable Flathub
echo "Enabling Flathub..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install Git
echo "Installing git..."
dnf install git -y
sudo -n -i -u jyuter git config --global user.name "Josh Yuter"
sudo -n -i -u jyuter git config --global user.email "jyuter@gmail.com"
dnf install gh -i

# Install Shell Commands
echo "Installing shell commands..."
dnf install zsh -y
dnf install util-linux -y
dnf install htop -y
dnf install neofetch -y
dnf install neovim -y
dnf install fzf -y
dnf install bat -y
dnf install exa -y
dnf install ffmpeg -y 
dnf install cpufetch -y
dnf install lsd -y
dnf install bpytop -y
dnf install speedtest-cli -y
dnf install lolcat -y
dnf install tmux -y
dnf install timetrap -y
dnf install ripgrep -y
dnf install zoxide -y
dnf install entr -y
dnf install mc -y
dnf install stow -y

#Install Fonts
echo "Installing fonts..."
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip \
&& cd ~/.local/share/fonts \
&& unzip JetBrainsMono.zip \
&& rm JetBrainsMono.zip \
&& fc-cache -fv

wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip \
&& cd ~/.local/share/fonts \
&& unzip -o Meslo.zip \
&& rm Meslo.zip \
&& fc-cache -fv

wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Lekton.zip \
&& cd ~/.local/share/fonts \
&& unzip -o Lekton.zip \
&& rm Lekton.zip \
&& fc-cache -fv

wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/RobotoMono.zip \
&& cd ~/.local/share/fonts \
&& unzip -o RobotoMono.zip \
&& rm RobotoMono.zip \
&& fc-cache -fv

wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Mononoki.zip \
&& cd ~/.local/share/fonts \
&& unzip -o Mononoki.zip \
&& rm Mononoki.zip \
&& fc-cache -fv

wget -P ~/.local/share/fonts https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip \
&& cd ~/.local/share/fonts \
&& unzip -o Hack-v3.003-ttf.zip \
&& rm Hack-v3.003-ttf.zip \
&& fc-cache -fv

# Shell Utils
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# Install Utilities
echo "Installing utilities..."
dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/40/winehq.repo -y
dnf install timeshift -y
dnf install dnfdragora -y
dnf install snapd -y

dnf group install --with-optional virtualization -y
systemctl start libvirtd
systemctl enable libvirtd
dnf install freerdp -y

dnf swap ffmpeg-free ffmpeg --allowerasing -y
dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
dnf update @sound-and-video -y
dnf install intel-media-driver -y

# Install Programming Tools
echo "Install development tools..."
dnf install dotnet-sdk-8.0 -y
dnf install gcc -y
dnf install elixir -y
dnf install php-cli phpunit composer -y
dnf install erlang -y

dnf install ruby -y
dnf install rubygem-{irb,rake,rbs,rexml,typeprof,test-unit} ruby-bundled-gems -y

dnf install rustup -y

dnf install golang -y
sudo -n -i -u jyuter mkdir -p ~/go
sudo -n -i -u jyuter echo 'export GOPATH=$HOME/go' >> ~/.bashrc
sudo -n -i -u jyuter source ~/.bashrc

dnf install nodejs -y
npm install -g npm@latest
npm install -g pnpm
npm install -g bun 

# Install Containers
echo "Installing containers..."
dnf install podman -y

dnf install dnf-plugins-core -y
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo 
dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

wget -O docker-desktop.rpm "https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm"
dnf install ./docker-desktop.rpm -y
rm ./docker-desktop.rpm 

systemctl start docker
systemctl enable docker

# Install VSCode
echo "Installing VS Code..."
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
dnf check-update
dnf install code -y

# Install Chrome
echo "Installing Chrome..."
dnf install fedora-workstation-repositories -y
dnf config-manager --set-enabled google-chrome 
dnf install google-chrome-stable -y

# Install Media
echo "Installing media..."
dnf install vlc -y
dnf group install Multimedia -y
dnf install mpv -y

# Install Flatpacks
flatpak install flathub com.jetbrains.PyCharm-Community -y
flatpak install flathub org.zotero.Zotero -y
flatpak install flathub com.google.AndroidStudio -y
flatpak install flathub com.bitwarden.desktop -y
flatpak install flathub io.github.giantpinkrobots.flatsweep -y
flatpak install flathub com.github.dail8859.NotepadNext -y
flatpak install flathub com.todoist.Todoist -y
flatpak install flathub com.github.PintaProject.Pinta -y
#flatpak install flathub xyz.z3ntu.razergenie -y
#flatpak install flathub md.obsidian.Obsidian -y
# flatpak install flathub org.audacityteam.Audacity -y
# flatpak install flathub com.obsproject.Studio -y
# flatpak install flathub org.gnome.Loupe -y
# flatpak install flathub com.spotify.Client -y

