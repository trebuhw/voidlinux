#!/bin/bash

set -e

log() {
    echo -e "\e[32m[INFO]\e[0m $1"
}

error() {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

success() {
    echo -e "\e[34m[SUCCESS]\e[0m $1"
}

warning() {
    echo -e "\e[33m[WARNING]\e[0m $1"
}

check_success() {
    if [ $? -ne 0 ]; then
        error "$1"
        exit 1
    fi
}

# Wykrywanie dystrybucji
if [ -f /etc/void-release ]; then
    DISTRO="void"
    log "Wykryto dystrybucję: Void Linux"
else
    error "Nieobsługiwana dystrybucja. Skrypt obsługuje tylko Void Linux."
    exit 1
fi

# Funkcja do synchronizacji repozytoriów Void
update_repos() {
    log "Aktualizacja repozytoriów..."
    sudo xbps-install -Su
    check_success "Nie udało się zaktualizować repozytoriów"
}

# Zależności DWM
install_dwm_deps() {
    log "Instalacja zależności DWM dla Void Linux..."
    sudo xbps-install -Sy base-devel libX11-devel libXinerama-devel libXft-devel xorg xorg-server xinit
    check_success "Nie udało się zainstalować zależności DWM"
}

# Pakiety dla Void Linux (odpowiedniki pakietów Arch Linux)
PACKAGES=(
    bash-completion bat blueman brightnessctl btop cups curl dunst feh file-roller firefox fish fzf galculator gcc gcr3 gnome-disk-utility gparted gsettings-desktop-schemas gzip htop i3lock kitty mako meld neovim numlockx p7zip-unrar parcellite pavucontrol pdfarranger picom ripgrep rofi rsync scrot stow sxhkd thunar thunar-archive-plugin thunar-volman time trash-cli tree tumbler unrar unzip vim vlc wget xclip xdg-user-dirs xfce4-notifyd zathura zoxide
    alacritty vscode eza fastfetch font-manager libreoffice libreoffice-i18n-pl polkit-gnome network-manager-applet nsxiv mlocate os-prober sddm starship tldr tlp qt5ct xf86-input-synaptics xf86-video-intel wezterm yazi
    lm_sensors nwg-look simple-sddm-theme ueberzug waypaper
)

# Instalacja pakietów z repozytoriów
install_repo_packages() {
    local pkgs=("$@")
    log "Instalacja pakietów z repozytoriów (xbps)..."
    sudo xbps-install -Sy "${pkgs[@]}"
    check_success "Nie udało się zainstalować pakietów z xbps"
}

# Specyficzne konfiguracje dla Void Linux
void_specific_configs() {
    log "Wykonywanie konfiguracji specyficznych dla Void Linux..."
    
    # Zmiana powłoki shell
    if command -v fish &> /dev/null; then
        log "Zmiana powłoki na fish..."
        chsh -s /bin/fish $USER && success "Powłoka zmieniona na fish. Wyloguj się, aby zastosować zmiany."
    fi
    
    # Włączanie i uruchamianie usług (korzystamy z runit zamiast systemd)
    log "Konfiguracja usług systemowych (runit)..."
    sudo ln -sf /etc/sv/NetworkManager /var/service/
    sudo ln -sf /etc/sv/cupsd /var/service/
    sudo ln -sf /etc/sv/dbus /var/service/ # Potrzebne dla wielu usług
    sudo ln -sf /etc/sv/sddm /var/service/
    sudo ln -sf /etc/sv/tlp /var/service/
    
    # Optymalizacja systemu
    log "Optymalizacja systemu Void..."
    echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null
    
    # Optymalizacja SSD (jeśli jest)
    if [ -d "/sys/block/sda/queue/rotational" ] && [ "$(cat /sys/block/sda/queue/rotational)" -eq 0 ]; then
        log "Wykryto SSD, optymalizacja..."
        echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.d/99-ssd.conf > /dev/null
        # Void używa fstrim.cron zamiast fstrim.timer z systemd
        sudo ln -sf /etc/sv/fstrim /var/service/
    fi

    # Skopiowanie konfiguracji SDDM
    [ -d /usr/share/sddm/themes/simple-sddm ] && sudo mv /usr/share/sddm/themes/simple-sddm /usr/share/sddm/themes/simple-sddm.bak
    [ -f /etc/sddm.conf.d ] && sudo mv /etc/sddm.conf.d /etc/sddm.conf.d.bak
    sudo cp -rv ~/.dotfiles/usr/.config/usr/share/sddm/themes/simple-sddm /usr/share/sddm/themes/
    sudo cp -rv ~/.dotfiles/etc/.config/sddm.conf.d /etc
}

# Wykonywanie głównego kodu skryptu
# ===================================================

# Aktualizacja repozytoriów
update_repos

# Instalacja zależności
install_dwm_deps

# Instalacja pakietów
log "Instalacja pakietów..."
install_repo_packages "${PACKAGES[@]}"
check_success "Nie udało się zainstalować pakietów"

log "Instalacja zakończona pomyślnie!"

# Klonowanie repozytorium
log "Klonowanie repozytorium dotfiles..."
if [ -d ~/.dotfiles ]; then
    read -p "Katalog ~/.dotfiles już istnieje. Czy chcesz go nadpisać? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/.dotfiles
    else
        error "Anulowano. Katalog ~/.dotfiles już istnieje."
        exit 1
    fi
fi

git clone --depth 1 https://github.com/trebuhw/.dotfiles ~/.dotfiles
check_success "Nie udało się sklonować repozytorium"

# Tworzenie kopii zapasowych
log "Tworzenie kopii zapasowych plików konfiguracyjnych..."
[ -f ~/.bashrc ] && mv ~/.bashrc ~/.bashrc.bak
[ -f ~/.bash_logout ] && mv ~/.bash_logout ~/.bash_logout.bak
[ -f ~/.bash_profile ] && mv ~/.bash_profile ~/.bash_profile.bak
[ -f ~/.gtkrc-2.0 ] && mv ~/.gtkrc-2.0 ~/.gtkrc-2.0.bak
[ -d ~/.config/gtk-2.0 ] && mv ~/.config/gtk-2.0 ~/gtk-2.0.bak
[ -d ~/.config/gtk-3.0 ] && mv ~/.config/gtk-3.0 ~/gtk-3.0.bak
[ -d ~/.config/gtk-4.0 ] && mv ~/.config/gtk-4.0 ~/gtk-4.0.bak

# Stow
log "Tworzenie symlinków za pomocą stow..."
cd ~/.dotfiles || { error "Nie można przejść do katalogu ~/.dotfiles"; exit 1; }
stow Xresources/ alacritty/ background/ bat/ bash/ bin/ btop/ dunst/ fish/ fonts/ gtk-2.0/ gtk-3.0/ gtk-4.0/ gtkrc-2.0/ hypr/ icons/ kitty/ mako/ mc/ nvim/ nsxiv/ parcellite/ qt5ct/ ranger/ rofi/ starship/ suckless/ sublime-text/ themes/ thunar/ tldr/ sxiv/ swappy/ swaylock/ vim/ xfce4/ xinitrc/ xprofile/ yazi/ waybar/ wezterm/ wlogout/ wofi/ zathura/
check_success "Błąd podczas wykonywania stow"

# Kompilacja i instalacja DWM
log "Kompilacja i instalacja DWM..."
cd ~/.config/suckless/dwm || { error "Nie można przejść do katalogu DWM"; exit 1; }
[ -f config.h ] && rm config.h
sudo make && sudo make clean install && rm -f config.h
check_success "Błąd podczas kompilacji DWM"

# Kompilacja i instalacja DMENU
log "Kompilacja i instalacja DMENU..."
cd ~/.config/suckless/dmenu || { error "Nie można przejść do katalogu DMENU"; exit 1; }
[ -f config.h ] && rm config.h
sudo make && sudo make clean install && rm -f config.h
check_success "Błąd podczas kompilacji DMENU"

# Kompilacja i instalacja slstatus
log "Kompilacja i instalacja slstatus..."
cd ~/.config/suckless/slstatus || { error "Nie można przejść do katalogu slstatus"; exit 1; }
[ -f config.h ] && rm config.h
sudo make && sudo make clean install && rm -f config.h
check_success "Błąd podczas kompilacji slstatus"

# Kompilacja i instalacja st
log "Kompilacja i instalacja st (terminal)..."
cd ~/.config/suckless/st || { error "Nie można przejść do katalogu st"; exit 1; }
sudo make && sudo make clean install
check_success "Błąd podczas kompilacji st"

# Instalacja pliku .desktop
log "Kopiowanie pliku .desktop..."
[ -d /usr/share/xsessions ] || sudo mkdir -p /usr/share/xsessions
sudo cp ~/.config/suckless/usr/share/xsessions/dwm.desktop /usr/share/xsessions/
check_success "Nie udało się skopiować pliku .desktop"

# Instalacja pliku start-dwm.sh uruchamiającego slstatus w autostarcie w GDM i SDDM
[ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin
sudo cp ~/.config/suckless/usr/local/bin/start-dwm.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/start-dwm.sh

log "Instalacja zakończona pomyślnie!"
log "Aby uruchomić DWM, wyloguj się i wybierz sesję DWM z menedżera logowania."

# Dodanie czcionek
sudo fc-cache -fv

# Ustawienie theme gtk
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'
gsettings set org.gnome.desktop.interface cursor-size 20 
gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Dark"
gsettings set org.gnome.desktop.wm.preferences theme "Catppuccin-Dark"
gsettings set org.gnome.desktop.interface icon-theme "Tela-circle-dracula-dark"
gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 10'
ln -sf ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini

# Ustawienie konfiguracji programów root
sudo mkdir -p /root/.config/
sudo ln -sf ~/dotfiles/gtkrc-2.0/.gtkrc-2.0 /root/.gtkrc-2.0
sudo ln -sf ~/dotfiles/vim/.vimrc /root/.vimrc
sudo ln -sf ~/dotfiles/vim/.viminfo /root/.viminfo
sudo ln -sf ~/dotfiles/nvim/.config/nvim /root/.config/nvim
sudo ln -sf ~/dotfiles/mc/.config/mc /root/.config/mc
sudo ln -sf ~/dotfiles/gtk-4.0/.config/gtk-4.0 /root/.config/gtk-4.0
sudo ln -sf ~/dotfiles/gtk-3.0/.config/gtk-3.0 /root/.config/gtk-3.0
sudo ln -sf ~/dotfiles/gtk-2.0/.config/gtk-2.0 /root/.config/gtk-2.0
sudo ln -sf ~/dotfiles/ranger/.config/ranger /root/.config/ranger

# TLP
[ -f /etc/tlp.conf ] && sudo mv /etc/tlp.conf /etc/tlp.conf.back
sudo ln -sf ~/.dotfiles/etc/.config/tlp.conf

# Wykonanie konfiguracji specyficznych dla Void Linux
log "Wykonywanie konfiguracji specyficznych dla Void Linux..."
void_specific_configs

# Pytanie o reboot
read -p "Czy chcesz teraz zrestartować system? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Restartuję system..."
    sudo reboot
fi

exit 0
