#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
source ./install_homebrew.sh

# Function to install mas (Mac App Store CLI)
# Parameters: None
# Returns: None
install_mas() {

    # Check if Homebrew is installed
    if is_homebrew_installed ; then
        echo "Homebrew is installed."
    else
        echo "Homebrew is not installed. Installing Homebrew..."
        install_homebrew
    fi



    # Check if mas is installed
    if ! is_mas_installed; then
        echo "mas not found, installing..."
        brew install mas
        echo "mas installation complete."
    else
        echo "mas is already installed."
    fi
}



# Function to check if mas (Mac App Store CLI) is installed
# Parameters: None
# Returns: 0 if mas is installed, 1 otherwise
is_mas_installed() {
    if command -v mas &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Export the functions for use in other scripts
export -f is_mas_installed
export -f install_mas

# Call the install_mas function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_mas
fi
