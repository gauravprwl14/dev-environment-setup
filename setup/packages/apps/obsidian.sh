#!/bin/bash

# packages/apps/obsidian.sh — Cross-platform Obsidian installation script.
#
# Obsidian is a powerful knowledge base and note-taking application that works
# on top of a local folder of plain text Markdown files.
#
# Platform support:
#   macOS          : Homebrew Cask
#   Debian/Fedora  : Flatpak (flathub md.obsidian.Obsidian)
#   Arch           : AUR helper via install_cask (yay/paru) with flatpak fallback

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"


# Function to check if Obsidian is installed.
# Detection strategy varies by platform:
#   macOS          : brew list --cask obsidian
#   Linux (all)    : command -v obsidian OR flatpak list check
# Parameters: None
# Returns: 0 if Obsidian is installed, 1 otherwise
is_obsidian_installed() {
    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            if brew list --cask obsidian &> /dev/null; then
                log_info "Obsidian is installed (Homebrew Cask)."
                return 0
            else
                log_info "Obsidian is not installed."
                return 1
            fi
            ;;
        debian|fedora|arch|linux)
            if command -v obsidian &> /dev/null; then
                log_info "Obsidian is installed (command found on PATH)."
                return 0
            fi
            if command -v flatpak &> /dev/null && flatpak list --app | grep -q "md.obsidian.Obsidian"; then
                log_info "Obsidian is installed (Flatpak)."
                return 0
            fi
            log_info "Obsidian is not installed."
            return 1
            ;;
        *)
            log_warn "is_obsidian_installed: unsupported OS '${os}' — assuming not installed."
            return 1
            ;;
    esac
}


# Function to install Obsidian.
# Installation strategy varies by platform:
#   macOS          : brew install --cask obsidian
#   Debian/Fedora  : flatpak install -y flathub md.obsidian.Obsidian
#   Arch           : install_cask obsidian (AUR via yay/paru, flatpak fallback)
# Parameters: None
# Returns: 0 on success, 1 on unsupported OS or install failure
install_obsidian() {
    local os
    os="$(detect_os)"

    if is_obsidian_installed; then
        log_success "Obsidian is already installed. Skipping."
        return 0
    fi

    log_step "Installing Obsidian..."

    case "${os}" in
        macos)
            install_cask obsidian
            ;;
        debian|fedora)
            flatpak install -y flathub md.obsidian.Obsidian
            ;;
        arch)
            install_cask obsidian
            ;;
        *)
            log_error "install_obsidian: unsupported OS '${os}'."
            return 1
            ;;
    esac

    log_success "Obsidian installation completed."
}


# Export functions so they are available when this script is sourced.
export -f is_obsidian_installed
export -f install_obsidian


# Run install_obsidian when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_obsidian
fi
