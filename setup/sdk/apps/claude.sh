#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
# This ensures Homebrew is available before attempting to install Claude
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"

# Function to check if Claude is installed
# Checks Homebrew Cask list for claude package
# Note: Claude Desktop may not be available via Homebrew Cask
# If installation fails, consider installing from official website
# Parameters: None
# Returns: 0 if Claude is installed, 1 otherwise
is_claude_installed() {
    # Check if claude cask is installed via Homebrew
    if brew list --cask | grep -q "claude"; then
        echo "Claude is installed."
        return 0
    else
        echo "Claude is not installed."
        return 1
    fi
}

# Function to install Claude Desktop
# Installs Claude Desktop application using Homebrew Cask if not already installed
# Claude is an AI assistant application by Anthropic
# Parameters: None
# Returns: None
install_claude() {
    # Ensure homebrew is installed before proceeding
    install_homebrew

    # Check if Claude is already installed to avoid re-installation
    if ! is_claude_installed; then
        echo "Installing Claude..."
        # Install Claude via Homebrew Cask
        # Note: If this fails, Claude may need to be installed from the official website
        brew install --cask claude
        echo "Claude installation completed."
    else
        echo "Claude is already installed."
    fi
}

# Export functions to make them available for sourcing in other scripts
export -f is_claude_installed
export -f install_claude

# Call the install function if this script is executed directly
# This allows the script to be run standalone or sourced from other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_claude
fi

