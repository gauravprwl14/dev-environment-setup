#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/homebrew.sh"
source "$(dirname "${BASH_SOURCE[0]}")/mas.sh"
source "$(dirname "${BASH_SOURCE[0]}")/watchman.sh"

install_xcode() {
    
    # Ensure homebrew is installed
    install_homebrew
    
    # Ensure mas is installed
    install_mas
    
    # Ensure watchman is installed
    install_watchman
    

    # Ensure Xcode is installed
    if ! is_xcode_installed; then
        echo "Xcode not found, installing..."

        mas install 497799835  # Xcode's Mac App Store ID

    else
        echo "Xcode is already installed."
    fi
}

# Function to check if Xcode is installed
# Parameters: None
# Returns: 0 if Xcode is installed, 1 otherwise
is_xcode_installed() {
    if [ -d "/Applications/Xcode.app" ]; then
        echo "Xcode is installed."
        return 0
    else
        echo "Xcode is not installed."
        return 1
    fi
}

install_xcode_command_line_tools() {
    # Check if the Command Line Tools are already installed
    if xcode-select --print-path &> /dev/null; then
        echo "Xcode Command Line Tools are already installed."
    else
        echo "Xcode Command Line Tools not found, installing..."

        # Trigger the installation of Command Line Tools
        xcode-select --install

        # Wait until the Command Line Tools are installed
        until xcode-select --print-path &> /dev/null; do
            echo "Waiting for Xcode Command Line Tools installation to complete..."
            sleep 5
        done

        echo "Xcode Command Line Tools installed successfully."
    fi
}

export -f is_xcode_installed
export -f install_xcode


# Call the install functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_xcode
fi