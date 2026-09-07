#!/bin/bash

# packages/apps/discord.sh — Cross-platform Discord installation script.
#
# Discord is a voice, video, and text chat app popular with developer and
# gaming communities.
#
# Platform support:
#   macOS          : Homebrew Cask (discord)
#   Debian/Fedora  : Flatpak (flathub com.discordapp.Discord)
#   Arch           : AUR helper via install_cask (yay/paru) with flatpak fallback

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"


# Function to check if Discord is installed.
# Detection strategy varies by platform:
#   macOS          : brew list --cask discord
#   Linux (all)    : command -v discord OR flatpak list check
# Parameters: None
# Returns: 0 if Discord is installed, 1 otherwise
is_discord_installed() {
    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            if brew list --cask discord &> /dev/null; then
                log_info "Discord is installed (Homebrew Cask)."
                return 0
            else
                log_info "Discord is not installed."
                return 1
            fi
            ;;
        debian|fedora|arch|linux)
            if command -v discord &> /dev/null; then
                log_info "Discord is installed (command found on PATH)."
                return 0
            fi
            if command -v flatpak &> /dev/null && flatpak list --app | grep -q "com.discordapp.Discord"; then
                log_info "Discord is installed (Flatpak)."
                return 0
            fi
            log_info "Discord is not installed."
            return 1
            ;;
        *)
            log_warn "is_discord_installed: unsupported OS '${os}' — assuming not installed."
            return 1
            ;;
    esac
}


# Function to install Discord.
# Installation strategy varies by platform:
#   macOS          : brew install --cask discord
#   Debian/Fedora  : flatpak install -y flathub com.discordapp.Discord
#   Arch           : install_cask discord (AUR via yay/paru, flatpak fallback)
# Parameters: None
# Returns: 0 on success, 1 on unsupported OS or install failure
install_discord() {
    local os
    os="$(detect_os)"

    if is_discord_installed; then
        log_success "Discord is already installed. Skipping."
        return 0
    fi

    log_step "Installing Discord..."

    case "${os}" in
        macos)
            install_cask discord || { log_error "install_discord: Homebrew Cask install failed."; return 1; }
            ;;
        debian|fedora)
            flatpak install -y flathub com.discordapp.Discord || { log_error "install_discord: flatpak install failed."; return 1; }
            ;;
        arch)
            install_cask discord || { log_error "install_discord: install failed (AUR/flatpak)."; return 1; }
            ;;
        *)
            log_error "install_discord: unsupported OS '${os}'."
            return 1
            ;;
    esac

    if is_discord_installed; then
        log_success "Discord installation completed."
    else
        log_error "Discord installation failed."
        return 1
    fi
}


# Export functions so they are available when this script is sourced.
export -f is_discord_installed
export -f install_discord


# Run install_discord when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_discord
fi
