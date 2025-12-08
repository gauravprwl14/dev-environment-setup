#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
# This ensures Homebrew is available before attempting to install Yarn
source "$(dirname "${BASH_SOURCE[0]}")/homebrew.sh"

# Function to check if Yarn is installed
# Checks if yarn command is available in the system PATH
# Parameters: None
# Returns: 0 if Yarn is installed, 1 otherwise
is_yarn_installed() {
    # Check if yarn command is available
    if command -v yarn &> /dev/null; then
        echo "Yarn is installed."
        return 0
    else
        echo "Yarn is not installed."
        return 1
    fi
}

# Function to install Yarn
# Installs Yarn package manager using Homebrew if not already installed
# Yarn is a fast, reliable, and secure dependency management tool for JavaScript
# It is an alternative to npm and provides better performance and security
# Parameters: None
# Returns: None
install_yarn() {
    # Ensure homebrew is installed before proceeding
    install_homebrew

    # Check if Yarn is already installed to avoid re-installation
    if ! is_yarn_installed; then
        echo "Installing Yarn..."
        # Install Yarn via Homebrew (not cask, as it's a command-line tool)
        brew install yarn
        echo "Yarn installation completed."
        
        # Verify installation by checking version
        if is_yarn_installed; then
            echo "Yarn version: $(yarn --version)"
        fi
    else
        echo "Yarn is already installed."
        # Display current version
        echo "Yarn version: $(yarn --version)"
    fi
}

# Export functions to make them available for sourcing in other scripts
export -f is_yarn_installed
export -f install_yarn

# Call the install function if this script is executed directly
# This allows the script to be run standalone or sourced from other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_yarn
fi

