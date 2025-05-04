# voidlinux

# Void Linux Package Management Guide

This guide provides essential commands for managing packages in Void Linux using the `xbps` package manager and `xbps-src` for building packages from source. It covers package installation, removal, updates, and source package management in the `~/void-packages` directory.

## Table of Contents

- [voidlinux](#voidlinux)
- [Void Linux Package Management Guide](#void-linux-package-management-guide)
  - [Table of Contents](#table-of-contents)
  - [XBPS Commands](#xbps-commands)
    - [Searching Packages](#searching-packages)
    - [Installing Packages](#installing-packages)
    - [Removing Packages](#removing-packages)
    - [Updating System and Repositories](#updating-system-and-repositories)
    - [Additional XBPS Commands](#additional-xbps-commands)
  - [XBPS-SRC Commands](#xbps-src-commands)
    - [Setup and Initialization](#setup-and-initialization)
    - [Building and Managing Source Packages](#building-and-managing-source-packages)
    - [Additional XBPS-SRC Commands](#additional-xbps-src-commands)
  - [Notes](#notes)

## XBPS Commands

`xbps` is the package manager for Void Linux, used to manage binary packages.

### Searching Packages

- **Search in repositories**:

  - **Command**: `xbps-query -Rs <package-name>`
  - **Description**: Searches for packages available in repositories matching the given name.
  - **Example**: `xbps-query -Rs firefox`

- **Search installed packages**:
  - **Command**: `xbps-query -s <package-name>`
  - **Description**: Searches for installed packages matching the given name.
  - **Example**: `xbps-query -s vim`

### Installing Packages

- **Install a package**:
  - **Command**: `xbps-install <package-name>`
  - **Description**: Installs the specified package and its dependencies.
  - **Example**: `xbps-install htop`
  - **Note**: Use `-S` (`xbps-install -S <package-name>`) to sync repositories before installation.

### Removing Packages

- **Remove a package with dependencies**:

  - **Command**: `xbps-remove -R <package-name>`
  - **Description**: Removes the specified package and unused dependencies.
  - **Example**: `xbps-remove -R gimp`

- **Remove orphaned packages**:
  - **Command**: `xbps-remove -O`
  - **Description**: Removes packages installed as dependencies but no longer needed.
  - **Example**: `xbps-remove -O`

### Updating System and Repositories

- **Update repositories**:

  - **Command**: `xbps-install -S`
  - **Description**: Synchronizes local repository indexes with remote servers.
  - **Example**: `xbps-install -S`

- **Update system**:
  - **Command**: `xbps-install -Su`
  - **Description**: Updates all installed packages to the latest versions.
  - **Example**: `xbps-install -Su`

### Additional XBPS Commands

- **Show package details**:

  - **Command**: `xbps-query <package-name>`
  - **Description**: Displays details about a package (version, dependencies, etc.).
  - **Example**: `xbps-query python3`

- **Clear package cache**:
  - **Command**: `xbps-remove -C`
  - **Description**: Removes old or unused package files from `/var/cache/xbps`.
  - **Example**: `xbps-remove -C`

## XBPS-SRC Commands

`xbps-src` is used to build and manage packages from source in the `~/void-packages` directory, typically a cloned repository (`git clone https://github.com/void-linux/void-packages.git`).

### Setup and Initialization

- **Initialize environment**:

  - **Command**: `./xbps-src binary-bootstrap`
  - **Description**: Sets up the `xbps-src` environment for building packages.
  - **Example**: `cd ~/void-packages && ./xbps-src binary-bootstrap`
  - **Note**: Use `binary-bootstrap musl` for Musl-based systems.

- **Update void-packages repository**:
  - **Command**: `git pull`
  - **Description**: Updates the local `void-packages` repository to the latest version.
  - **Example**: `cd ~/void-packages && git pull`

### Building and Managing Source Packages

- **Build a package**:

  - **Command**: `./xbps-src pkg <package-name>`
  - **Description**: Builds and installs a package from source in a chroot environment.
  - **Example**: `./xbps-src pkg firefox`

- **Install a built package**:

  - **Command**: `xbps-install -R hostdir/binpkgs/nonfree <package-name>`
  - **Description**: Installs a binary package built by `xbps-src` from `hostdir/binpkgs`.
  - **Example**: `xbps-install -R ~/void-packages/hostdir/binpkgs htop`
  - **Note**: Requires root privileges (`sudo`).

- **Search available package templates**:
  - **Command**: `ls srcpkgs/ | grep <name>`
  - **Description**: Lists package templates in `srcpkgs/` matching the given name.
  - **Example**: `ls srcpkgs/ | grep vim`

### Additional XBPS-SRC Commands

- **Clean build environment**:

  - **Command**: `./xbps-src clean`
  - **Description**: Removes temporary files and directories from the build process.
  - **Example**: `./xbps-src clean`

- **Reset build environment**:

  - **Command**: `./xbps-src zap`
  - **Description**: Removes all build dependencies and resets the chroot environment.
  - **Example**: `./xbps-src zap`

- **Show package details**:

  - **Command**: `./xbps-src show <package-name>`
  - **Description**: Displays information about a package template (dependencies, version, etc.).
  - **Example**: `./xbps-src show python3`

- **Build without installing**:

  - **Command**: `./xbps-src -C pkg <package-name>`
  - **Description**: Builds a package without installing it in the chroot.
  - **Example**: `./xbps-src -C pkg vim`

- **Create a new package template**:
  - **Command**: `./xbps-src create <package-name>`
  - **Description**: Starts a wizard to create a new package template in `srcpkgs/`.
  - **Example**: `./xbps-src create mypackage`

## Notes

- **Root privileges**: Commands like `xbps-install`, `xbps-remove`, or installing built packages require `sudo`.
- **Dry run**: Use `-n` (e.g., `xbps-install -n htop`) to simulate actions without making changes.
- **Repositories**: Ensure correct repository configuration in `/etc/xbps.d/` for `xbps` and `~/void-packages/etc/conf` for `xbps-src`.
- **Documentation**: Refer to `man xbps`, `man xbps-src`, or the [Void Handbook](https://docs.voidlinux.org/) for more details.
- **Disk space**: Building packages with `xbps-src` requires sufficient disk space, especially in the chroot environment.

For further assistance or specific use cases, open an issue in this repository or consult the Void Linux community.
