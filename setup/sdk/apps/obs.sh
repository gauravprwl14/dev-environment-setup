#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
# This ensures Homebrew is available before attempting to install OBS Studio
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"

# Function to check if OBS Studio is installed
# Checks Homebrew Cask list for obs package
# Parameters: None
# Returns: 0 if OBS Studio is installed, 1 otherwise
is_obs_installed() {
    # Check if obs cask is installed via Homebrew
    if brew list --cask | grep -q "obs"; then
        echo "OBS Studio is installed."
        return 0
    else
        echo "OBS Studio is not installed."
        return 1
    fi
}

# Function to install OBS Studio
# Installs OBS Studio using Homebrew Cask if not already installed
# OBS Studio is a free and open-source software for video recording and live streaming
# Parameters: None
# Returns: None
install_obs() {
    # Ensure homebrew is installed before proceeding
    install_homebrew

    # Check if OBS Studio is already installed to avoid re-installation
    if ! is_obs_installed; then
        echo "Installing OBS Studio..."
        # Install OBS Studio via Homebrew Cask
        brew install --cask obs
        echo "OBS Studio installation completed."
    else
        echo "OBS Studio is already installed."
    fi
}

# Export functions to make them available for sourcing in other scripts
export -f is_obs_installed
export -f install_obs

# Call the install function if this script is executed directly
# This allows the script to be run standalone or sourced from other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_obs
fi

