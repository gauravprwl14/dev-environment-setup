#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
# This ensures Homebrew is available before attempting to install Cursor
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"

# Function to check if Cursor is installed
# Checks Homebrew Cask list for cursor package
# Parameters: None
# Returns: 0 if Cursor is installed, 1 otherwise
is_cursor_installed() {
    # Check if cursor cask is installed via Homebrew
    if brew list --cask | grep -q "cursor"; then
        echo "Cursor is installed."
        return 0
    else
        echo "Cursor is not installed."
        return 1
    fi
}

# Function to install Cursor
# Installs Cursor IDE using Homebrew Cask if not already installed
# Cursor is an AI-powered code editor based on VS Code
# Parameters: None
# Returns: None
install_cursor() {
    # Ensure homebrew is installed before proceeding
    install_homebrew

    # Check if Cursor is already installed to avoid re-installation
    if ! is_cursor_installed; then
        echo "Installing Cursor..."
        # Install Cursor via Homebrew Cask
        brew install --cask cursor
        echo "Cursor installation completed."
    else
        echo "Cursor is already installed."
    fi
}

# Export functions to make them available for sourcing in other scripts
export -f is_cursor_installed
export -f install_cursor

# Call the install function if this script is executed directly
# This allows the script to be run standalone or sourced from other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_cursor
fi

