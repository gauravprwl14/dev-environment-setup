#!/bin/bash

# packages/apps/openvpn.sh — Cross-platform OpenVPN installation helper.
# Supports macOS (Homebrew Cask for GUI + Homebrew for CLI), Debian/Ubuntu (apt),
# Fedora/RHEL (dnf), and Arch (pacman).
# On macOS, installs both the openvpn-connect GUI client and the openvpn CLI tool.
# On Linux, installs openvpn plus the appropriate NetworkManager plugin for the distro.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"


# Function to check if OpenVPN is installed.
# Uses command -v so it works on all platforms regardless of package manager.
# Parameters: None
# Returns: 0 if openvpn binary is found on PATH, 1 otherwise
is_openvpn_installed() {
    if command -v openvpn &> /dev/null; then
        log_success "OpenVPN is installed."
        return 0
    else
        log_info "OpenVPN is not installed."
        return 1
    fi
}


# Function to install OpenVPN for the current platform.
# On macOS, installs the openvpn-connect GUI cask and the openvpn CLI formula.
# On Debian/Ubuntu, installs openvpn and network-manager-openvpn.
# On Fedora/RHEL, installs openvpn and NetworkManager-openvpn.
# On Arch, installs openvpn.
# Parameters: None
# Returns: 0 on success, 1 on unsupported OS
install_openvpn() {
    local os
    os="$(detect_os)"

    if ! is_openvpn_installed; then
        case "${os}" in
            macos)
                log_step "Installing OpenVPN Connect (GUI) via Homebrew Cask..."
                install_cask openvpn-connect
                log_success "OpenVPN Connect installation completed."
                log_step "Installing OpenVPN CLI via Homebrew..."
                install_pkg openvpn
                log_success "OpenVPN CLI installation completed."
                ;;
            debian)
                log_step "Installing OpenVPN and NetworkManager plugin via apt..."
                install_pkg openvpn
                install_pkg network-manager-openvpn
                log_success "OpenVPN installation completed."
                ;;
            fedora)
                log_step "Installing OpenVPN and NetworkManager plugin via dnf..."
                install_pkg openvpn
                install_pkg NetworkManager-openvpn
                log_success "OpenVPN installation completed."
                ;;
            arch)
                log_step "Installing OpenVPN via pacman..."
                install_pkg openvpn
                log_success "OpenVPN installation completed."
                ;;
            *)
                log_error "install_openvpn: unsupported OS '${os}'"
                return 1
                ;;
        esac
    else
        log_info "OpenVPN is already installed. Skipping installation."
    fi
}


export -f is_openvpn_installed
export -f install_openvpn


# Run install when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_openvpn
fi
