# Instrukcja obsługi skryptu `void-update-chrome.sh`

Ten skrypt automatycznie aktualizuje przeglądarkę Google Chrome w systemie Void Linux za pomocą narzędzia `xbps-src`. Pobiera najnowszą wersję Chrome, generuje sumę kontrolną, aktualizuje szablon pakietu i instaluje go.

## Wymagania
- **System**: Void Linux (z skonfigurowanym `xbps-src`).
- **Powłoka**: Bash (skrypt jest w Bash, ale można go uruchamiać z Fish).
- **Zależności**:
  - `jq`, `wget`, `coreutils`, `sed`, `git` (instalowane automatycznie przez skrypt).
  - Zainstaluj ręcznie, jeśli wolisz:
    ```bash
    sudo xbps-install -S jq wget coreutils sed git
    ```
- **Szablon Google Chrome**:
  - Musi istnieć w `~/void-packages/srcpkgs/google-chrome/template`.
  - Jeśli nie istnieje, utwórz go (patrz sekcja poniżej).
- **Uprawnienia**: Dostęp do `sudo` dla instalacji pakietów.
- **Internet**: Połączenie do pobierania wersji Chrome i pliku `.deb`.

## Utworzenie szablonu Google Chrome
Jeśli szablon nie istnieje w `~/void-packages/srcpkgs/google-chrome`, wykonaj:
```bash
mkdir -p ~/void-packages/srcpkgs/google-chrome
nano ~/void-packages/srcpkgs/google-chrome/template
```
Wklej:
```bash
# Template file for 'google-chrome'
pkgname=google-chrome
version=137.0.XXXX.XX
revision=1
_chromeVersion=${version}
short_desc="Google Chrome web browser"
maintainer="Your Name <your.email@example.com>"
license="custom:chrome"
homepage="https://www.google.com/chrome/"
distfiles="https://dl.google.com/linux/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${version}-1_amd64.deb"
checksum="calculate_checksum_here"
restricted=yes
build_style=meta
depends="libstdc++ glib nss nspr cups libX11"

do_install() {
    vbin ${FILESDIR}/google-chrome
    vinstall ${FILESDIR}/google-chrome.desktop 0644 usr/share/applications
}
```
Utwórz plik wrappera:
```bash
mkdir -p ~/void-packages/srcpkgs/google-chrome/files
nano ~/void-packages/srcpkgs/google-chrome/files/google-chrome
```
Wklej:
```bash
#!/bin/sh
exec /opt/google/chrome/google-chrome "$@"
```
Nadaj uprawnienia:
```bash
chmod +x ~/void-packages/srcpkgs/google-chrome/files/google-chrome
```
Utwórz plik `.desktop`:
```bash
nano ~/void-packages/srcpkgs/google-chrome/files/google-chrome.desktop
```
Wklej:
```bash
[Desktop Entry]
Name=Google Chrome
Exec=google-chrome %U
Type=Application
Icon=google-chrome
Categories=Network;WebBrowser;
```

## Jak działa skrypt
Skrypt wykonuje następujące kroki:
1. Sprawdza i instaluje zależności (`jq`, `wget`, `coreutils`, `sed`, `git`).
2. Weryfikuje istnienie katalogu `~/void-packages` i szablonu `google-chrome`.
3. Ustawia zmienną `XBPS_DISTDIR` i inicjalizuje środowisko `xbps-src`.
4. Włącza obsługę pakietów z ograniczoną licencją (`nonfree`).
5. Aktualizuje repozytorium `void-packages` przez `git pull`.
6. Pobiera najnowszą wersję Chrome z API Chrome for Testing.
7. Pobiera plik `.deb` z `dl.google.com`.
8. Generuje sumę kontrolną SHA256.
9. Aktualizuje pola `version` i `checksum` w szablonie.
10. Buduje pakiet za pomocą `xbps-src pkg google-chrome`.
11. Instaluje pakiet z lokalnego repozytorium `nonfree`.
12. Usuwa tymczasowy plik `.deb`.

## Uruchamianie skryptu
1. Upewnij się, że skrypt ma uprawnienia do wykonywania:
   ```bash
   chmod +x ~/pCloudDrive/Notes/void-update-chrome.sh
   ```
2. Uruchom skrypt:
   ```bash
   bash ~/pCloudDrive/Notes/void-update-chrome.sh
   ```
   lub, jeśli używasz powłoki Fish:
   ```fish
   bash ~/pCloudDrive/Notes/void-update-chrome.sh
   ```

## Automatyzacja za pomocą crontab
Aby skrypt uruchamiał się automatycznie (np. codziennie o 8:00):
1. Edytuj crontab:
   ```bash
   crontab -e
   ```
2. Dodaj linię:
   ```bash
   0 8 * * * /bin/bash /home/user/pCloudDrive/Notes/void-update-chrome.sh >> /var/log/chrome-update.log 2>&1
   ```
   - Zastąp `/home/user/pCloudDrive/Notes` swoją ścieżką do skryptu.
   - Logi będą zapisywane w `/var/log/chrome-update.log`.

## Rozwiązywanie problemów
- **Błąd pobierania pliku**:
  - Sprawdź, czy URL w szablonie (`distfiles`) jest poprawny.
  - Weryfikuj wersję Chrome na [Google Chrome Releases](https://chromereleases.googleblog.com/).
- **Błąd budowania**:
  - Sprawdź logi w `~/void-packages/hostdir/buildlogs/google-chrome`.
  - Upewnij się, że wszystkie zależności są zainstalowane.
- **Błąd crontab**:
  - Sprawdź logi w `/var/log/chrome-update.log`.
  - Upewnij się, że ścieżka do skryptu i Bash (`/bin/bash`) jest poprawna.
- **Brak szablonu**:
  - Utwórz szablon zgodnie z instrukcją powyżej.
- **Alternatywa**:
  - Jeśli Google Chrome sprawia problemy, rozważ użycie Chromium:
    ```bash
    cd ~/void-packages
    ./xbps-src pkg chromium
    sudo xbps-install --repository=hostdir/binpkgs chromium
    ```

## Uwagi
- Skrypt wymaga połączenia z internetem do pobierania wersji i pliku `.deb`.
- Upewnij się, że masz uprawnienia `sudo` do instalacji pakietów.
- Regularnie aktualizuj repozytorium `void-packages` (`git pull origin master`).
- Skrypt jest w Bash, ale działa w środowisku Fish, jeśli uruchamiany przez `bash`.
