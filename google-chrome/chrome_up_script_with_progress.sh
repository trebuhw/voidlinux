#!/bin/bash
# Skrypt do aktualizacji Google Chrome w Void Linux za pomocą xbps-src
VOID_PACKAGES_DIR="$HOME/void-packages"
TEMPLATE_FILE="${VOID_PACKAGES_DIR}/srcpkgs/google-chrome/template"

# 1. Sprawdzanie zależności
for pkg in jq wget coreutils sed git; do
    if ! command -v "$pkg" >/dev/null; then
        echo "Instalowanie $pkg..."
        sudo xbps-install -S "$pkg" || {
            echo "Błąd: Nie udało się zainstalować $pkg"
            exit 1
        }
    fi
done

# 2. Sprawdzanie katalogu
if [ ! -d "$VOID_PACKAGES_DIR" ]; then
    echo "Błąd: Katalog $VOID_PACKAGES_DIR nie istnieje!"
    exit 1
fi

cd "$VOID_PACKAGES_DIR" || {
    echo "Błąd: Nie można przejść do $VOID_PACKAGES_DIR"
    exit 1
}

# 3. Ustawienie XBPS_DISTDIR
export XBPS_DISTDIR=$(pwd)

# 4. Inicjalizacja środowiska xbps-src
echo "Inicjalizowanie środowiska xbps-src..."
./xbps-src binary-bootstrap || {
    echo "Błąd: Nie udało się zainicjalizować środowiska xbps-src"
    exit 1
}

# 5. Włączenie pakietów nonfree
if ! grep -q "XBPS_ALLOW_RESTRICTED=yes" etc/conf; then
    echo "XBPS_ALLOW_RESTRICTED=yes" >> etc/conf
fi

# 6. Aktualizacja repozytorium
echo "Aktualizowanie repozytorium void-packages..."
git pull origin master || {
    echo "Błąd: Nie udało się zaktualizować repozytorium"
    exit 1
}

# 7. Pobieranie numeru wersji
echo "Pobieranie najnowszej wersji Google Chrome..."
CHROME_VERSION=$(curl -s https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions.json | jq -r '.channels.Stable.version')
if [ -z "$CHROME_VERSION" ]; then
    echo "Błąd: Nie udało się pobrać numeru wersji"
    exit 1
fi
CHROME_URL="https://dl.google.com/linux/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}-1_amd64.deb"

# 8. Sprawdzanie szablonu
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Błąd: Szablon google-chrome nie istnieje w $TEMPLATE_FILE!"
    echo "Utwórz szablon ręcznie, korzystając z dokumentacji Void Linux."
    exit 1
fi

# 9. Pobieranie pliku i generowanie sumy kontrolnej z paskiem postępu
echo "Pobieranie pliku dla wersji $CHROME_VERSION..."
echo "Rozmiar pliku: ~110MB"
wget --progress=bar:force "$CHROME_URL" -O "google-chrome-stable_${CHROME_VERSION}-1_amd64.deb" || {
    echo "Błąd: Nie udało się pobrać pliku. Sprawdź wersję lub URL."
    exit 1
}

echo "Generowanie sumy kontrolnej..."
CHECKSUM=$(sha256sum "google-chrome-stable_${CHROME_VERSION}-1_amd64.deb" | cut -d ' ' -f 1)
if [ -z "$CHECKSUM" ]; then
    echo "Błąd: Nie udało się wygenerować sumy kontrolnej"
    exit 1
fi

# 10. Aktualizacja szablonu
echo "Aktualizowanie szablonu dla wersji $CHROME_VERSION..."
sed -i "s/version=.*/version=$CHROME_VERSION/" "$TEMPLATE_FILE"
sed -i "s/checksum=.*/checksum=\"$CHECKSUM\"/" "$TEMPLATE_FILE"

# 11. Budowanie pakietu
echo "Budowanie pakietu Google Chrome..."
./xbps-src pkg google-chrome || {
    echo "Błąd: Nie udało się zbudować pakietu. Sprawdź logi w hostdir/buildlogs/google-chrome."
    exit 1
}

# 12. Instalacja pakietu
echo "Instalowanie Google Chrome..."
sudo xbps-install --repository=hostdir/binpkgs/nonfree -u google-chrome -y || {
    echo "Błąd: Nie udało się zainstalować pakietu"
    exit 1
}

# 13. Czyszczenie
rm -f "google-chrome-stable_${CHROME_VERSION}-1_amd64.deb"
echo "Google Chrome zaktualizowany do wersji $CHROME_VERSION!"