#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
# This ensures Homebrew is available before attempting to install OpenVPN (Tunnelblick)
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"

# Function to check if Tunnelblick (OpenVPN GUI client) is installed
# Checks Homebrew Cask list for tunnelblick package
# Parameters: None
# Returns: 0 if Tunnelblick is installed, 1 otherwise
is_openvpn_installed() {
    # Check if tunnelblick cask is installed via Homebrew
    if brew list --cask | grep -q "tunnelblick"; then
        echo "Tunnelblick (OpenVPN client) is installed."
        return 0
    else
        echo "Tunnelblick (OpenVPN client) is not installed."
        return 1
    fi
}

# Function to install Tunnelblick (OpenVPN GUI client)
# Installs Tunnelblick using Homebrew Cask if not already installed
# Tunnelblick is a free, open-source GUI client for OpenVPN on macOS
# It provides an easy-to-use interface for managing VPN connections
# Parameters: None
# Returns: None
install_openvpn() {
    # Ensure homebrew is installed before proceeding
    install_homebrew

    # Check if Tunnelblick is already installed to avoid re-installation
    if ! is_openvpn_installed; then
        echo "Installing Tunnelblick (OpenVPN GUI client)..."
        # Install Tunnelblick via Homebrew Cask
        brew install --cask tunnelblick
        echo "Tunnelblick (OpenVPN client) installation completed."
    else
        echo "Tunnelblick (OpenVPN client) is already installed."
    fi
}

# Export functions to make them available for sourcing in other scripts
export -f is_openvpn_installed
export -f install_openvpn

# Call the install function if this script is executed directly
# This allows the script to be run standalone or sourced from other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_openvpn
fi

