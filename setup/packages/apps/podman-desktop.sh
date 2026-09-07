#!/bin/bash

# packages/apps/podman-desktop.sh — Cross-platform Podman Desktop installation script.
#
# Podman Desktop is the official GUI for managing Podman containers, pods, and
# machines.
#
# Platform support:
#   macOS          : Homebrew Cask (official Podman Desktop app)
#   Debian/Fedora  : Flatpak (official distribution channel — flathub)
#   Arch           : AUR helper (yay/paru) with Flatpak fallback

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"


# Flatpak application ID for Podman Desktop (used on Debian/Fedora/Arch fallback).
_PODMAN_DESKTOP_FLATPAK_ID="io.podman_desktop.PodmanDesktop"


# Function to check if Podman Desktop is installed.
# Detection strategy varies by platform:
#   macOS          : brew list --cask podman-desktop
#   Linux (all)    : flatpak list check OR AUR-installed binary on PATH
# Parameters: None
# Returns: 0 if Podman Desktop is installed, 1 otherwise
is_podman_desktop_installed() {
    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            if brew list --cask podman-desktop &> /dev/null; then
                log_info "Podman Desktop is installed (Homebrew Cask)."
                return 0
            else
                log_info "Podman Desktop is not installed."
                return 1
            fi
            ;;
        debian|fedora|arch|linux)
            if command -v podman-desktop &> /dev/null; then
                log_info "Podman Desktop is installed (command found on PATH)."
                return 0
            fi
            if command -v flatpak &> /dev/null && flatpak list --app | grep -q "${_PODMAN_DESKTOP_FLATPAK_ID}"; then
                log_info "Podman Desktop is installed (Flatpak)."
                return 0
            fi
            log_info "Podman Desktop is not installed."
            return 1
            ;;
        *)
            log_warn "is_podman_desktop_installed: unsupported OS '${os}' — assuming not installed."
            return 1
            ;;
    esac
}


# Function to install Podman Desktop.
# Installation strategy varies by platform:
#   macOS          : brew install --cask podman-desktop
#   Debian/Fedora  : flatpak install -y flathub io.podman_desktop.PodmanDesktop
#   Arch           : AUR helper (yay/paru) for podman-desktop-bin, Flatpak fallback
# Parameters: None
# Returns: 0 on success, 1 on unsupported OS or install failure
install_podman_desktop() {
    local os
    os="$(detect_os)"

    if is_podman_desktop_installed; then
        log_success "Podman Desktop is already installed. Skipping."
        return 0
    fi

    log_step "Installing Podman Desktop..."

    case "${os}" in
        macos)
            install_cask podman-desktop
            ;;
        debian|fedora)
            if command -v flatpak &> /dev/null; then
                flatpak install -y flathub "${_PODMAN_DESKTOP_FLATPAK_ID}"
            else
                log_error "install_podman_desktop: flatpak is required but not available." \
                          "Install flatpak and re-run this script."
                return 1
            fi
            ;;
        arch)
            if command -v yay &> /dev/null; then
                yay -S --noconfirm podman-desktop-bin
            elif command -v paru &> /dev/null; then
                paru -S --noconfirm podman-desktop-bin
            elif command -v flatpak &> /dev/null; then
                flatpak install -y flathub "${_PODMAN_DESKTOP_FLATPAK_ID}"
            else
                log_error "install_podman_desktop: no AUR helper or flatpak found on Arch."
                return 1
            fi
            ;;
        *)
            log_error "install_podman_desktop: unsupported OS '${os}'."
            return 1
            ;;
    esac

    log_success "Podman Desktop installation completed."
}


# Export functions so they are available when this script is sourced.
export -f is_podman_desktop_installed
export -f install_podman_desktop


# Run install_podman_desktop when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_podman_desktop
fi
