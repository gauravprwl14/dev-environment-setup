#!/bin/bash
# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../mas.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../watchman.sh"



# Function to check if Telegram is installed
is_telegram_installed() {
    if mas list | grep -q "747648890"; then
        echo "Telegram is installed."
        return 0
    else
        echo "Telegram is not installed."
        return 1
    fi
}

install_telegram() {

    # Ensure homebrew is installed
    install_homebrew
        
    # Ensure mas is installed
    install_mas
        
     # Ensure watchman is installed
     install_watchman
    


    if ! is_telegram_installed; then
        echo "Telegram not found, installing..."
        mas install 747648890  # Telegram's Mac App Store ID
    else
        echo "Telegram is already installed."
    fi
}

export -f is_telegram_installed
export -f install_telegram

# Call the install function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_telegram
fi

