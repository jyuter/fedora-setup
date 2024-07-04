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

# Enable RPM Fusion
echo "Enabling RPM Fusion..."
dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y
dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y

# Firmware Updates
echo "Updating firmware..."
fwupdmgr refresh --force
fwupdmgr get-updates
fwupdmgr update -y

# Enable Flathub
echo "Enabling Flathub..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install Git
echo "Installing git..."
dnf install git -y
sudo -n -i -u jyuter git config --global user.name "Josh Yuter"
sudo -n -i -u jyuter git config --global user.email "jyuter@gmail.com"

# Install Shell Commands
echo "Installing shell commands..."
dnf install zsh -y
dnf install util-linux -y
dnf install alacritty -y
dnf install htop -y
dnf install neofetch -y
dnf install neovim -y
dnf install fzf -y
dnf install ripgrep -y
dnf install bat -y
dnf install exa -y
dnf install ffmpeg -y 
dnf install cpufetch -y
dnf install gdu -y
dnf install lsd -y
dnf install bpytop -y
dnf install speedtest-cli -y
dnf install lolcat -y

# Install Utilities
echo "Installing utilities..."
dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/40/winehq.repo -y
dnf install timeshift -y
dnf install dnfdragora -y

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
sudo -n -i -u jyuter mkdir -p $HOME/go
sudo -n -i -u jyuter echo 'export GOPATH=$HOME/go' >> $HOME/.bashrc
sudo -n -i -u jyuter source $HOME/.bashrc

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

wget -O docker-desktop.rpm "https://desktop.docker.com/linux/main/amd64/149282/docker-desktop-4.30.0-x86_64.rpm"
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

# Install Themes
dnf install Lightly -y
