#!/bin/bash

# Package manager abstraction library.
# Provides cross-platform install/remove/service helpers by delegating to
# the OS-specific package manager detected by detect_os.sh.

source "$(dirname "${BASH_SOURCE[0]}")/detect_os.sh"


# install_pkg <name>
# Installs a CLI package via the correct package manager for the current OS.
install_pkg() {
    local pkg="$1"

    case "$(detect_os)" in
        macos)
            brew install "$pkg"
            ;;
        debian)
            sudo apt-get install -y "$pkg"
            ;;
        fedora)
            sudo dnf install -y "$pkg"
            ;;
        arch)
            sudo pacman -S --noconfirm "$pkg"
            ;;
        *)
            echo "install_pkg: unsupported OS '$(detect_os)'" >&2
            return 1
            ;;
    esac
}


# install_cask <name>
# Installs a GUI application via the correct mechanism for the current OS.
#   macOS  : Homebrew Cask
#   Debian / Fedora : Flatpak (flathub) with snap fallback
#   Arch   : AUR helper (yay/paru) with flatpak fallback
install_cask() {
    local name="$1"

    case "$(detect_os)" in
        macos)
            brew install --cask "$name"
            ;;
        debian|fedora)
            if command -v flatpak &> /dev/null; then
                flatpak install -y flathub "$name"
            else
                sudo snap install "$name"
            fi
            ;;
        arch)
            if command -v yay &> /dev/null; then
                yay -S --noconfirm "$name"
            elif command -v paru &> /dev/null; then
                paru -S --noconfirm "$name"
            elif command -v flatpak &> /dev/null; then
                flatpak install -y flathub "$name"
            else
                echo "install_cask: no AUR helper or flatpak found on Arch" >&2
                return 1
            fi
            ;;
        *)
            echo "install_cask: unsupported OS '$(detect_os)'" >&2
            return 1
            ;;
    esac
}


# remove_pkg <name>
# Removes a package via the correct package manager for the current OS.
remove_pkg() {
    local pkg="$1"

    case "$(detect_os)" in
        macos)
            brew uninstall "$pkg"
            ;;
        debian)
            sudo apt-get remove -y "$pkg"
            ;;
        fedora)
            sudo dnf remove -y "$pkg"
            ;;
        arch)
            sudo pacman -R --noconfirm "$pkg"
            ;;
        *)
            echo "remove_pkg: unsupported OS '$(detect_os)'" >&2
            return 1
            ;;
    esac
}


# update_pkg_manager
# Updates / refreshes the package manager index for the current OS.
update_pkg_manager() {
    case "$(detect_os)" in
        macos)
            brew update
            ;;
        debian)
            sudo apt-get update
            ;;
        fedora)
            sudo dnf check-update || true
            ;;
        arch)
            sudo pacman -Sy
            ;;
        *)
            echo "update_pkg_manager: unsupported OS '$(detect_os)'" >&2
            return 1
            ;;
    esac
}


# add_service <name>
# Enables and starts a service.
#   macOS : brew services start
#   Linux : systemctl enable --now
add_service() {
    local name="$1"

    case "$(detect_os)" in
        macos)
            brew services start "$name"
            ;;
        debian|fedora|arch)
            sudo systemctl enable --now "$name"
            ;;
        *)
            echo "add_service: unsupported OS '$(detect_os)'" >&2
            return 1
            ;;
    esac
}


# stop_service <name>
# Stops a running service.
#   macOS : brew services stop
#   Linux : systemctl stop
stop_service() {
    local name="$1"

    case "$(detect_os)" in
        macos)
            brew services stop "$name"
            ;;
        debian|fedora|arch)
            sudo systemctl stop "$name"
            ;;
        *)
            echo "stop_service: unsupported OS '$(detect_os)'" >&2
            return 1
            ;;
    esac
}


# is_pkg_installed <name>
# Returns 0 if the binary is available on PATH, 1 otherwise.
is_pkg_installed() {
    local name="$1"

    if command -v "$name" &> /dev/null; then
        return 0
    else
        return 1
    fi
}


# is_brew_pkg_installed <name>
# Returns 0 if the package is listed by Homebrew, 1 otherwise.
# Only meaningful on macOS; returns 1 immediately on other platforms.
is_brew_pkg_installed() {
    local name="$1"

    if [[ "$(detect_os)" != "macos" ]]; then
        return 1
    fi

    if brew list "$name" &> /dev/null; then
        return 0
    else
        return 1
    fi
}


export -f install_pkg
export -f install_cask
export -f remove_pkg
export -f update_pkg_manager
export -f add_service
export -f stop_service
export -f is_pkg_installed
export -f is_brew_pkg_installed


# When executed directly, print the detected OS and the active package manager.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    os="$(detect_os)"
    echo "Detected OS: $os"

    case "$os" in
        macos)   echo "Package manager: brew" ;;
        debian)  echo "Package manager: apt-get" ;;
        fedora)  echo "Package manager: dnf" ;;
        arch)    echo "Package manager: pacman" ;;
        *)       echo "Package manager: unknown" ;;
    esac
fi
