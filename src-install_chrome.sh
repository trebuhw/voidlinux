#!/bin/bash

set -e

log() {
    echo -e "\e[32m[INFO]\e[0m $1"
}

error() {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

check_success() {
    if [ $? -ne 0 ]; then
        error "$1"
        exit 1
    fi
}

# Wykrywanie dystrybucji
if grep -q '^ID=void' /etc/os-release 2>/dev/null || [ -d /run/runit ]; then
    log "Wykryto dystrybucję: Void Linux"
else
    error "Nieobsługiwana dystrybucja. Skrypt obsługuje tylko Void Linux."
    exit 1
fi

# Instalacja Google Chrome za pomocą xbps-src
log "Instalacja zależności dla xbps-src..."
sudo xbps-install -Sy git base-devel
check_success "Nie udało się zainstalować zależności dla xbps-src"

# Klonowanie void-packages
if [ -d ~/void-packages ]; then
    log "Katalog ~/void-packages już istnieje, aktualizowanie..."
    cd ~/void-packages
    git pull origin master
    check_success "Nie udało się zaktualizować void-packages"
else
    log "Klonowanie repozytorium void-packages..."
    git clone https://github.com/void-linux/void-packages.git ~/void-packages
    check_success "Nie udało się sklonować void-packages"
fi

# Konfiguracja xbps-src
cd ~/void-packages
log "Konfiguracja xbps-src..."
./xbps-src binary-bootstrap
check_success "Nie udało się skonfigurować xbps-src"
echo "XBPS_ALLOW_RESTRICTED=yes" >> etc/conf
check_success "Nie udało się włączyć obsługi pakietów nonfree"

# Kompilacja i instalacja google-chrome
log "Kompilacja pakietu google-chrome..."
./xbps-src pkg google-chrome
check_success "Nie udało się skompilować google-chrome"
sudo xbps-install --repository=hostdir/binpkgs/nonfree google-chrome
check_success "Nie udało się zainstalować google-chrome"

# Czyszczenie po instalacji
log "Czyszczenie tymczasowych plików void-packages..."
cd ~
rm -rf ~/void-packages
check_success "Nie udało się usunąć katalogu void-packages"

log "Instalacja Google Chrome zakończona pomyślnie!"
exit 0