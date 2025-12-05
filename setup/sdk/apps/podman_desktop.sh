#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
# This ensures Homebrew is available before attempting to install Podman Desktop
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"

# Function to check if Podman Desktop is installed
# Checks Homebrew Cask list for podman-desktop package
# Parameters: None
# Returns: 0 if Podman Desktop is installed, 1 otherwise
is_podman_desktop_installed() {
    # Check if podman-desktop cask is installed via Homebrew
    if brew list --cask | grep -q "podman-desktop"; then
        echo "Podman Desktop is installed."
        return 0
    else
        echo "Podman Desktop is not installed."
        return 1
    fi
}

# Function to install Podman Desktop
# Installs Podman Desktop using Homebrew Cask if not already installed
# Podman Desktop is a GUI application for managing Podman containers
# Parameters: None
# Returns: None
install_podman_desktop() {
    # Ensure homebrew is installed before proceeding
    install_homebrew

    # Check if Podman Desktop is already installed to avoid re-installation
    if ! is_podman_desktop_installed; then
        echo "Installing Podman Desktop..."
        # Install Podman Desktop via Homebrew Cask
        brew install --cask podman-desktop
        echo "Podman Desktop installation completed."
    else
        echo "Podman Desktop is already installed."
    fi
}

# Export functions to make them available for sourcing in other scripts
export -f is_podman_desktop_installed
export -f install_podman_desktop

# Call the install function if this script is executed directly
# This allows the script to be run standalone or sourced from other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_podman_desktop
fi

