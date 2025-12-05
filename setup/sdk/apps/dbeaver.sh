#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
# This ensures Homebrew is available before attempting to install DBeaver
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"

# Function to check if DBeaver is installed
# Checks Homebrew Cask list for dbeaver-community package
# Parameters: None
# Returns: 0 if DBeaver is installed, 1 otherwise
is_dbeaver_installed() {
    # Check if dbeaver-community cask is installed via Homebrew
    if brew list --cask | grep -q "dbeaver-community"; then
        echo "DBeaver is installed."
        return 0
    else
        echo "DBeaver is not installed."
        return 1
    fi
}

# Function to install DBeaver Community Edition
# Installs DBeaver using Homebrew Cask if not already installed
# Parameters: None
# Returns: None
install_dbeaver() {
    # Ensure homebrew is installed before proceeding
    install_homebrew

    # Check if DBeaver is already installed to avoid re-installation
    if ! is_dbeaver_installed; then
        echo "Installing DBeaver Community Edition..."
        # Install DBeaver Community Edition via Homebrew Cask
        brew install --cask dbeaver-community
        echo "DBeaver installation completed."
    else
        echo "DBeaver is already installed."
    fi
}

# Export functions to make them available for sourcing in other scripts
export -f is_dbeaver_installed
export -f install_dbeaver

# Call the install function if this script is executed directly
# This allows the script to be run standalone or sourced from other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_dbeaver
fi

