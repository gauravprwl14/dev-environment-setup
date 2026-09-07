#!/bin/bash

# packages/apps/vlc.sh — Cross-platform VLC media player installation script.
#
# VLC is a free and open-source cross-platform media player.
#
# Platform support:
#   macOS          : Homebrew Cask
#   Debian/Fedora  : Flatpak (flathub org.videolan.VLC)
#   Arch           : AUR helper via install_cask (yay/paru) with flatpak fallback

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"


# Function to check if VLC is installed.
# Detection strategy varies by platform:
#   macOS          : brew list --cask vlc
#   Linux (all)    : command -v vlc OR flatpak list check
# Parameters: None
# Returns: 0 if VLC is installed, 1 otherwise
is_vlc_installed() {
    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            if brew list --cask vlc &> /dev/null; then
                log_info "VLC is installed (Homebrew Cask)."
                return 0
            else
                log_info "VLC is not installed."
                return 1
            fi
            ;;
        debian|fedora|arch|linux)
            if command -v vlc &> /dev/null; then
                log_info "VLC is installed (command found on PATH)."
                return 0
            fi
            if command -v flatpak &> /dev/null && flatpak list --app | grep -q "org.videolan.VLC"; then
                log_info "VLC is installed (Flatpak)."
                return 0
            fi
            log_info "VLC is not installed."
            return 1
            ;;
        *)
            log_warn "is_vlc_installed: unsupported OS '${os}' — assuming not installed."
            return 1
            ;;
    esac
}


# Function to install VLC.
# Installation strategy varies by platform:
#   macOS          : brew install --cask vlc
#   Debian/Fedora  : flatpak install -y flathub org.videolan.VLC
#   Arch           : install_cask vlc (AUR via yay/paru, flatpak fallback)
# Parameters: None
# Returns: 0 on success, 1 on unsupported OS or install failure
install_vlc() {
    local os
    os="$(detect_os)"

    if is_vlc_installed; then
        log_success "VLC is already installed. Skipping."
        return 0
    fi

    log_step "Installing VLC..."

    case "${os}" in
        macos)
            install_cask vlc || { log_error "install_vlc: Homebrew Cask install failed."; return 1; }
            ;;
        debian|fedora)
            flatpak install -y flathub org.videolan.VLC || { log_error "install_vlc: flatpak install failed."; return 1; }
            ;;
        arch)
            install_cask vlc || { log_error "install_vlc: install failed (AUR/flatpak)."; return 1; }
            ;;
        *)
            log_error "install_vlc: unsupported OS '${os}'."
            return 1
            ;;
    esac

    if is_vlc_installed; then
        log_success "VLC installation completed."
    else
        log_error "VLC installation failed."
        return 1
    fi
}


# Export functions so they are available when this script is sourced.
export -f is_vlc_installed
export -f install_vlc


# Run install_vlc when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_vlc
fi
