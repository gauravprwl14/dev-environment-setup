#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
# This ensures Homebrew is available before attempting to install Kdenlive
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"

# Function to check if Kdenlive is installed
# Checks Homebrew Cask list for kdenlive package
# Parameters: None
# Returns: 0 if Kdenlive is installed, 1 otherwise
is_kdenlive_installed() {
    # Check if kdenlive cask is installed via Homebrew
    if brew list --cask | grep -q "kdenlive"; then
        echo "Kdenlive is installed."
        return 0
    else
        echo "Kdenlive is not installed."
        return 1
    fi
}

# Function to install Kdenlive
# Installs Kdenlive video editor using Homebrew Cask if not already installed
# Kdenlive is a free and open-source video editing software
# Parameters: None
# Returns: None
install_kdenlive() {
    # Ensure homebrew is installed before proceeding
    install_homebrew

    # Check if Kdenlive is already installed to avoid re-installation
    if ! is_kdenlive_installed; then
        echo "Installing Kdenlive..."
        # Install Kdenlive via Homebrew Cask
        brew install --cask kdenlive
        echo "Kdenlive installation completed."
    else
        echo "Kdenlive is already installed."
    fi
}

# Export functions to make them available for sourcing in other scripts
export -f is_kdenlive_installed
export -f install_kdenlive

# Call the install function if this script is executed directly
# This allows the script to be run standalone or sourced from other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_kdenlive
fi

