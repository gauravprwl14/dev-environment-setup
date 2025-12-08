#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
# This ensures Homebrew is available before attempting to install Obsidian
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"

# Function to check if Obsidian is installed
# Checks Homebrew Cask list for obsidian package
# Parameters: None
# Returns: 0 if Obsidian is installed, 1 otherwise
is_obsidian_installed() {
    # Check if obsidian cask is installed via Homebrew
    if brew list --cask | grep -q "obsidian"; then
        echo "Obsidian is installed."
        return 0
    else
        echo "Obsidian is not installed."
        return 1
    fi
}

# Function to install Obsidian
# Installs Obsidian using Homebrew Cask if not already installed
# Obsidian is a powerful knowledge base and note-taking application
# It works on top of a local folder of plain text Markdown files
# Parameters: None
# Returns: None
install_obsidian() {
    # Ensure homebrew is installed before proceeding
    install_homebrew

    # Check if Obsidian is already installed to avoid re-installation
    if ! is_obsidian_installed; then
        echo "Installing Obsidian..."
        # Install Obsidian via Homebrew Cask
        brew install --cask obsidian
        echo "Obsidian installation completed."
    else
        echo "Obsidian is already installed."
    fi
}

# Export functions to make them available for sourcing in other scripts
export -f is_obsidian_installed
export -f install_obsidian

# Call the install function if this script is executed directly
# This allows the script to be run standalone or sourced from other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_obsidian
fi

