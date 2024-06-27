# Update DNF Conf
echo "fastestmirror=True" >> /etc/dnf/dnf.conf
echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
echo "defaultyes=True" >> /etc/dnf/dnf.conf
echo "keepchache=True" >> /etc/dnf/dnf.conf

# Enable RPM Fusion
dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y
dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y

# Enable Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install Shell Commands
dnf install zsh
sudo -u jyuter chsh -s $(which zsh)
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

dnf install util-linux
dnf install alacritty
dnf install htop
dnf install neofetch
dnf install neovim
dnf install fzf
dnf install ripgrep
dnf install bat
dnf install exa

# Install Programming Languages
dnf install dotnet-sdk-8.0
dnf install gcc
dnf install elixir
dnf install php-cli phpunit composer
dnf install erlang

dnf install ruby
dnf install rubygem-{irb,rake,rbs,rexml,typeprof,test-unit} ruby-bundled-gems

dnf install rustup

dnf install golang
mkdir -p $HOME/go
echo 'export GOPATH=$HOME/go' >> $HOME/.bashrc
source $HOME/.bashrc

dnf install nodejs
npm install -g npm@latest
npm install -g pnpm
npm install -g bun 

# Install Containers
dnf install podman

dnf install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo 
dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl start docker
systemctl enable docker

# Install VSCode
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
dnf check-update
dnf install code

# Install Chrome
dnf install fedora-workstation-repositories
dnf config-manager --set-enabled google-chrome 
dnf install google-chrome-stable

# Install Media
dnf install vlc

# Install Flatpacks
flatpak install flathub com.todoist.Todoist -y
flatpak install flathub com.brave.Browser -y
flatpak install flathub org.telegram.desktop -y
flatpak install flathub com.spotify.Client -y
flatpak install flathub us.zoom.Zoom -y
flatpak install flathub com.github.PintaProject.Pinta -y
flatpak install flathub io.github.mimbrero.WhatsAppDesktop -y
flatpak install flathub com.getpostman.Postman -y
flatpak install flathub io.github.giantpinkrobots.flatsweep -y
flatpak install flathub org.videolan.VLC -y
flatpak install flathub md.obsidian.Obsidian -y
flatpak install flathub io.podman_desktop.PodmanDesktop -y


# Final upgrade and cleanup
dnf upgrade --refresh
dnf autoremove
