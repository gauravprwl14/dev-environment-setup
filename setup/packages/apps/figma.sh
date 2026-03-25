#!/bin/bash

# packages/apps/figma.sh — Cross-platform Figma installation script.
#
# Figma is a collaborative interface design tool. The official native desktop
# client is macOS/Windows only. On Linux the community-maintained figma-linux
# project provides a third-party wrapper; users should be aware it is not
# an official Figma release.
#
# Platform support:
#   macOS          : Homebrew Cask (official Figma desktop app)
#   Debian/Fedora  : Snap (figma-linux) with Flatpak fallback
#                    (io.github.Figma_Linux.Figma_Linux)
#   Arch           : AUR helper via install_cask (yay/paru) with Flatpak fallback

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"


# Function to check if Figma is installed.
# Detection strategy varies by platform:
#   macOS          : brew list --cask figma
#   Linux (all)    : command -v figma OR snap check figma-linux OR flatpak list check
# Parameters: None
# Returns: 0 if Figma is installed, 1 otherwise
is_figma_installed() {
    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            if brew list --cask figma &> /dev/null; then
                log_info "Figma is installed (Homebrew Cask)."
                return 0
            else
                log_info "Figma is not installed."
                return 1
            fi
            ;;
        debian|fedora|arch|linux)
            if command -v figma &> /dev/null; then
                log_info "Figma is installed (command found on PATH)."
                return 0
            fi
            if command -v snap &> /dev/null && snap list figma-linux &> /dev/null; then
                log_info "Figma is installed (Snap — figma-linux)."
                return 0
            fi
            if command -v flatpak &> /dev/null && flatpak list --app | grep -q "io.github.Figma_Linux.Figma_Linux"; then
                log_info "Figma is installed (Flatpak — figma-linux)."
                return 0
            fi
            log_info "Figma is not installed."
            return 1
            ;;
        *)
            log_warn "is_figma_installed: unsupported OS '${os}' — assuming not installed."
            return 1
            ;;
    esac
}


# Function to install Figma.
# Installation strategy varies by platform:
#   macOS          : brew install --cask figma
#   Debian/Fedora  : sudo snap install figma-linux, with Flatpak fallback
#                    (io.github.Figma_Linux.Figma_Linux)
#   Arch           : install_cask figma-linux (AUR via yay/paru, Flatpak fallback)
#
# NOTE: On Linux, Figma is primarily a web-based tool. The desktop app installed
# here (figma-linux) is a third-party, community-maintained project and is not
# an official release from Figma, Inc. For the most stable experience on Linux,
# consider using Figma in the browser at https://www.figma.com.
# Parameters: None
# Returns: 0 on success, 1 on unsupported OS or install failure
install_figma() {
    local os
    os="$(detect_os)"

    if is_figma_installed; then
        log_success "Figma is already installed. Skipping."
        return 0
    fi

    log_step "Installing Figma..."

    case "${os}" in
        macos)
            install_cask figma
            ;;
        debian|fedora)
            log_warn "On Linux, the Figma desktop app is provided by the third-party" \
                     "figma-linux project and is not an official Figma, Inc. release." \
                     "Consider using Figma in the browser at https://www.figma.com."
            if command -v snap &> /dev/null; then
                sudo snap install figma-linux
            elif command -v flatpak &> /dev/null; then
                flatpak install -y flathub io.github.Figma_Linux.Figma_Linux
            else
                log_error "install_figma: neither snap nor flatpak is available." \
                          "Install one of them and re-run this script."
                return 1
            fi
            ;;
        arch)
            log_warn "On Linux, the Figma desktop app is provided by the third-party" \
                     "figma-linux project and is not an official Figma, Inc. release." \
                     "Consider using Figma in the browser at https://www.figma.com."
            install_cask figma-linux
            ;;
        *)
            log_error "install_figma: unsupported OS '${os}'."
            return 1
            ;;
    esac

    log_success "Figma installation completed."
}


# Export functions so they are available when this script is sourced.
export -f is_figma_installed
export -f install_figma


# Run install_figma when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_figma
fi
