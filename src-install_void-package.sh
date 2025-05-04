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

# Sprawdzanie, czy podano argument
if [ -z "$1" ]; then
    error "Nie podano nazwy pakietu. Użycie: $0 <nazwa-pakietu>"
    exit 1
fi

PACKAGE_NAME="$1"

# Wykrywanie dystrybucji
if grep -q '^ID=void' /etc/os-release 2>/dev/null || [ -d /run/runit ]; then
    log "Wykryto dystrybucję: Void Linux"
else
    error "Nieobsługiwana dystrybucja. Skrypt obsługuje tylko Void Linux."
    exit 1
fi

# Instalacja zależności dla xbps-src
log "Instalacja zależności dla xbps-src..."
sudo xbps-install -Sy git base-devel
check_success "Nie udało się zainstalować zależności dla xbps-src"

# Klonowanie lub aktualizacja void-packages
if [ -d ~/void-packages ]; then
    log "Katalog ~/void-packages już istnieje, sprawdzanie aktualizacji..."
    cd ~/void-packages
    git fetch origin
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/master)" ]; then
        log "Aktualizowanie void-packages..."
        git pull origin master
        check_success "Nie udało się zaktualizować void-packages"
    else
        log "void-packages jest już aktualne"
    fi
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

# Przeszukiwanie pakietów w srcpkgs
log "Przeszukiwanie pakietów pasujących do '$PACKAGE_NAME' w ~/void-packages/srcpkgs..."
mapfile -t MATCHING_PACKAGES < <(find srcpkgs/ -maxdepth 1 -type d -name "*$PACKAGE_NAME*" -exec basename {} \;)

if [ ${#MATCHING_PACKAGES[@]} -eq 0 ]; then
    error "Nie znaleziono pakietów pasujących do '$PACKAGE_NAME' w ~/void-packages/srcpkgs"
    exit 1
elif [ ${#MATCHING_PACKAGES[@]} -eq 1 ]; then
    SELECTED_PACKAGE="${MATCHING_PACKAGES[0]}"
    log "Znaleziono jeden pasujący pakiet: $SELECTED_PACKAGE"
else
    log "Znaleziono kilka pasujących pakietów:"
    PS3="Wybierz numer pakietu do instalacji: "
    select pkg in "${MATCHING_PACKAGES[@]}"; do
        if [ -n "$pkg" ]; then
            SELECTED_PACKAGE="$pkg"
            log "Wybrano pakiet: $SELECTED_PACKAGE"
            break
        else
            error "Nieprawidłowy wybór. Spróbuj ponownie."
        fi
    done
fi

# Kompilacja i instalacja wybranego pakietu
log "Kompilacja pakietu $SELECTED_PACKAGE..."
./xbps-src pkg "$SELECTED_PACKAGE"
check_success "Nie udało się skompilować pakietu $SELECTED_PACKAGE"

# Sprawdzanie, czy pakiet jest w nonfree
if [ -f "hostdir/binpkgs/nonfree/$SELECTED_PACKAGE"*.xbps ]; then
    log "Instalacja pakietu $SELECTED_PACKAGE z repozytorium nonfree..."
    sudo xbps-install --repository=hostdir/binpkgs/nonfree "$SELECTED_PACKAGE"
else
    log "Instalacja pakietu $SELECTED_PACKAGE z repozytorium standardowego..."
    sudo xbps-install --repository=hostdir/binpkgs/nonfree "$SELECTED_PACKAGE"
fi
check_success "Nie udało się zainstalować pakietu $SELECTED_PACKAGE"

log "Instalacja pakietu $SELECTED_PACKAGE zakończona pomyślnie!"
exit 0
