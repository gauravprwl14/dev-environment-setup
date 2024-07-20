#!/bin/bash
# Source the Homebrew install script to ensure Homebrew is installed
# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/homebrew.sh"



install_watchman() {
    # Ensure watchman is installed
    if ! is_watchman_installed; then
        echo "watchman not found, installing..."

        brew install watchman

    else
        echo "watchman is already installed."
    fi
}

# Function to check if watchman is installed
# Parameters: None
# Returns: 0 if watchman is installed, 1 otherwise
is_watchman_installed() {
    if command -v watchman &> /dev/null; then
        echo "watchman is installed."
        return 0
    else
        echo "watchman is not installed."
        return 1
    fi
}


export -f is_watchman_installed
export -f install_watchman

# Call the install_mas function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_watchman
fi