# Enable RPM Fusion
dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y
dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y

# Enable Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install Shell Commands
dnf install zsh -y
dnf install util-linux -y
dnf install alacritty -y
dnf install htop -y
dnf install neofetch -y
dnf install neovim -y
dnf install fzf -y
dnf install ripgrep -y
dnf install bat -y

# Install Programming Languages
dnf install dotnet-sdk-8.0 -y
dnf install gcc -y
dnf install elixir -y
dnf install php-cli phpunit composer -y
dnf install erlang -y

dnf install ruby -y
dnf install rubygem-{irb,rake,rbs,rexml,typeprof,test-unit} ruby-bundled-gems -y

dnf install rustup -y

dnf install golang -y
mkdir -p $HOME/go
echo 'export GOPATH=$HOME/go' >> $HOME/.bashrc
source $HOME/.bashrc

dnf install nodejs -y
npm install -g npm@latest
npm install -g pnpm
npm install -g bun 

# Install Containers
dnf install podman -y

dnf install dnf-plugins-core -y
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo 
dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

systemctl start docker
systemctl enable docker

# Install VSCode
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
dnf check-update
dnf install code -y

# Install Chrome
dnf install fedora-workstation-repositories -y
dnf config-manager --set-enabled google-chrome 
dnf install google-chrome-stable -y

# Download Flatpacks
flatpak install flathub org.zotero.Zotero
flatpak install flathub com.todoist.Todoist
flatpak install flathub com.brave.Browser
flatpak install flathub org.telegram.desktop
flatpak install flathub com.spotify.Client
flatpak install flathub com.bitwarden.desktop
flatpak install flathub us.zoom.Zoom
flatpak install flathub com.github.PintaProject.Pinta
flatpak install flathub org.signal.Signal
flatpak install flathub io.github.mimbrero.WhatsAppDesktop
flatpak install flathub org.audacityteam.Audacity
flatpak install flathub com.getpostman.Postman
flatpak install flathub io.github.giantpinkrobots.flatsweep
flatpak install flathub org.videolan.VLC
flatpak install flathub md.obsidian.Obsidian
flatpak install flathub io.podman_desktop.PodmanDesktop

# Final upgrade and cleanup
dnf -y upgrade --refresh
dnf autoremove