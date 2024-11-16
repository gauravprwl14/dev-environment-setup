#!/bin/bash
# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../mas.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../watchman.sh"

# Function to check if VLC is installed
is_vlc_installed() {
    if brew list --cask | grep -q "vlc"; then
        echo "VLC is installed."
        return 0
    else
        echo "VLC is not installed."
        return 1
    fi
}

install_vlc() {
    # Ensure homebrew is installed
    install_homebrew
        

    if ! is_vlc_installed; then
        echo "VLC not found, installing..."
        brew install --cask vlc
    else
        echo "VLC is already installed."
    fi
}

export -f is_vlc_installed
export -f install_vlc

# Call the install function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_vlc
fi
