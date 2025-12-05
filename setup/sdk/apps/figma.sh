#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
# This ensures Homebrew is available before attempting to install Figma
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"

# Function to check if Figma is installed
# Checks Homebrew Cask list for figma package
# Parameters: None
# Returns: 0 if Figma is installed, 1 otherwise
is_figma_installed() {
    # Check if figma cask is installed via Homebrew
    if brew list --cask | grep -q "figma"; then
        echo "Figma is installed."
        return 0
    else
        echo "Figma is not installed."
        return 1
    fi
}

# Function to install Figma
# Installs Figma design tool using Homebrew Cask if not already installed
# Figma is a collaborative interface design tool
# Parameters: None
# Returns: None
install_figma() {
    # Ensure homebrew is installed before proceeding
    install_homebrew

    # Check if Figma is already installed to avoid re-installation
    if ! is_figma_installed; then
        echo "Installing Figma..."
        # Install Figma via Homebrew Cask
        brew install --cask figma
        echo "Figma installation completed."
    else
        echo "Figma is already installed."
    fi
}

# Export functions to make them available for sourcing in other scripts
export -f is_figma_installed
export -f install_figma

# Call the install function if this script is executed directly
# This allows the script to be run standalone or sourced from other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_figma
fi

