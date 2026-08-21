#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
# This ensures Homebrew is available before attempting to install Antigravity
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"

# Function to check if Antigravity is installed
# Checks Homebrew Cask list for antigravity package
# Parameters: None
# Returns: 0 if Antigravity is installed, 1 otherwise
is_antigravity_installed() {
    # Check if antigravity cask is installed via Homebrew
    if brew list --cask | grep -q "antigravity"; then
        echo "Antigravity is installed."
        return 0
    else
        echo "Antigravity is not installed."
        return 1
    fi
}

# Function to install Antigravity
# Installs Antigravity using Homebrew Cask if not already installed
# Parameters: None
# Returns: None
install_antigravity() {
    # Ensure homebrew is installed before proceeding
    install_homebrew

    # Check if Antigravity is already installed to avoid re-installation
    if ! is_antigravity_installed; then
        echo "Installing Antigravity..."
        # Install Antigravity via Homebrew Cask
        brew install --cask antigravity
        echo "Antigravity installation completed."
    else
        echo "Antigravity is already installed."
    fi
}

# Export functions to make them available for sourcing in other scripts
export -f is_antigravity_installed
export -f install_antigravity

# Call the install function if this script is executed directly
# This allows the script to be run standalone or sourced from other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_antigravity
fi
