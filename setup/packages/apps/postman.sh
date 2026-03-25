#!/bin/bash

# packages/apps/postman.sh — Cross-platform Postman installation script.
# Supports macOS (Homebrew Cask), Debian-based and Fedora-based (snap),
# and Arch Linux (AUR helper or flatpak).

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"


# is_postman_installed
# Returns 0 if Postman is installed, 1 otherwise.
#   macOS : checks Homebrew Cask list for postman
#   Linux : checks for the postman binary on PATH or via snap
# Parameters: None
# Returns: 0 if Postman is installed, 1 otherwise
is_postman_installed() {
    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            if brew list --cask postman &> /dev/null; then
                log_info "Postman is installed."
                return 0
            else
                log_info "Postman is not installed."
                return 1
            fi
            ;;
        *)
            if command -v postman &> /dev/null; then
                log_info "Postman is installed."
                return 0
            elif command -v snap &> /dev/null && snap list postman &> /dev/null; then
                log_info "Postman is installed (snap)."
                return 0
            else
                log_info "Postman is not installed."
                return 1
            fi
            ;;
    esac
}


# install_postman
# Installs Postman using the appropriate method for the current OS:
#   macOS          : Homebrew Cask (brew install --cask postman)
#   Debian / Fedora: sudo snap install postman
#   Arch           : AUR helper (yay/paru) or flatpak via install_cask
# Parameters: None
# Returns: None
install_postman() {
    if is_postman_installed; then
        log_info "Postman is already installed."
        print_postman_version
        return 0
    fi

    local os
    os="$(detect_os)"

    log_step "Installing Postman (OS: ${os})"

    case "${os}" in
        macos)
            log_info "Installing Postman via Homebrew Cask..."
            install_cask postman
            ;;

        debian|fedora)
            log_info "Installing Postman via snap..."
            sudo snap install postman
            ;;

        arch)
            log_info "Installing Postman via AUR helper or flatpak..."
            install_cask postman
            ;;

        *)
            log_error "install_postman: unsupported OS '${os}'"
            return 1
            ;;
    esac

    if is_postman_installed; then
        log_success "Postman installation completed."
        print_postman_version
    else
        log_error "Postman installation failed."
        return 1
    fi
}


# print_postman_version
# Prints the installed Postman version if the postman binary is available on PATH.
# Parameters: None
# Returns: None
print_postman_version() {
    if command -v postman &> /dev/null; then
        log_info "Postman version: $(postman --version 2>/dev/null || echo 'version unavailable')"
    else
        log_debug "Postman binary not on PATH; version check skipped."
    fi
}


export -f is_postman_installed
export -f install_postman
export -f print_postman_version


# Call the install function if this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_postman
fi
