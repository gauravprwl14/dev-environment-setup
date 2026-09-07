#!/bin/bash

# packages/apps/telegram.sh — Cross-platform Telegram Desktop installation script.
#
# Telegram Desktop is the official desktop client for the Telegram messaging
# service.
#
# Platform support:
#   macOS          : Homebrew Cask (telegram)
#   Debian/Fedora  : Flatpak (flathub org.telegram.desktop)
#   Arch           : AUR helper via install_cask (yay/paru) with flatpak fallback

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"


# Function to check if Telegram is installed.
# Detection strategy varies by platform:
#   macOS          : brew list --cask telegram
#   Linux (all)    : command -v telegram-desktop OR flatpak list check
# Parameters: None
# Returns: 0 if Telegram is installed, 1 otherwise
is_telegram_installed() {
    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            if brew list --cask telegram &> /dev/null; then
                log_info "Telegram is installed (Homebrew Cask)."
                return 0
            else
                log_info "Telegram is not installed."
                return 1
            fi
            ;;
        debian|fedora|arch|linux)
            if command -v telegram-desktop &> /dev/null; then
                log_info "Telegram is installed (command found on PATH)."
                return 0
            fi
            if command -v flatpak &> /dev/null && flatpak list --app | grep -q "org.telegram.desktop"; then
                log_info "Telegram is installed (Flatpak)."
                return 0
            fi
            log_info "Telegram is not installed."
            return 1
            ;;
        *)
            log_warn "is_telegram_installed: unsupported OS '${os}' — assuming not installed."
            return 1
            ;;
    esac
}


# Function to install Telegram.
# Installation strategy varies by platform:
#   macOS          : brew install --cask telegram
#   Debian/Fedora  : flatpak install -y flathub org.telegram.desktop
#   Arch           : install_cask telegram-desktop (AUR via yay/paru, flatpak fallback)
# Parameters: None
# Returns: 0 on success, 1 on unsupported OS or install failure
install_telegram() {
    local os
    os="$(detect_os)"

    if is_telegram_installed; then
        log_success "Telegram is already installed. Skipping."
        return 0
    fi

    log_step "Installing Telegram..."

    case "${os}" in
        macos)
            install_cask telegram || { log_error "install_telegram: Homebrew Cask install failed."; return 1; }
            ;;
        debian|fedora)
            flatpak install -y flathub org.telegram.desktop || { log_error "install_telegram: flatpak install failed."; return 1; }
            ;;
        arch)
            install_cask telegram-desktop || { log_error "install_telegram: install failed (AUR/flatpak)."; return 1; }
            ;;
        *)
            log_error "install_telegram: unsupported OS '${os}'."
            return 1
            ;;
    esac

    if is_telegram_installed; then
        log_success "Telegram installation completed."
    else
        log_error "Telegram installation failed."
        return 1
    fi
}


# Export functions so they are available when this script is sourced.
export -f is_telegram_installed
export -f install_telegram


# Run install_telegram when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_telegram
fi
