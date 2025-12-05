#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
# This ensures Homebrew is available before attempting to install Postman
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"

# Function to check if Postman is installed
# Checks Homebrew Cask list for postman package
# Parameters: None
# Returns: 0 if Postman is installed, 1 otherwise
is_postman_installed() {
    # Check if postman cask is installed via Homebrew
    if brew list --cask | grep -q "postman"; then
        echo "Postman is installed."
        return 0
    else
        echo "Postman is not installed."
        return 1
    fi
}

# Function to install Postman
# Installs Postman API testing tool using Homebrew Cask if not already installed
# Postman is a popular API development and testing platform
# Parameters: None
# Returns: None
install_postman() {
    # Ensure homebrew is installed before proceeding
    install_homebrew

    # Check if Postman is already installed to avoid re-installation
    if ! is_postman_installed; then
        echo "Installing Postman..."
        # Install Postman via Homebrew Cask
        brew install --cask postman
        echo "Postman installation completed."
    else
        echo "Postman is already installed."
    fi
}

# Export functions to make them available for sourcing in other scripts
export -f is_postman_installed
export -f install_postman

# Call the install function if this script is executed directly
# This allows the script to be run standalone or sourced from other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_postman
fi

