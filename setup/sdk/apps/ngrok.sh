#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"

# Function to check if ngrok is installed
is_ngrok_installed() {
    if command -v ngrok &> /dev/null
    then
        return 0
    else
        return 1
    fi
}

# Function to install ngrok using Homebrew
install_ngrok() {
    
    if ! is_ngrok_installed; then 

        # Ensure homebrew is installed
        install_homebrew
        
        echo "ngrok is not installed. Installing..."
        brew install ngrok/ngrok/ngrok
        
        if [ $? -eq 0 ]; then
            echo "ngrok installed successfully."
        else
            echo "Failed to install ngrok."
            exit 1
        fi
    fi
}

# Function to print the ngrok version
print_ngrok_version() {
    echo "ngrok version:"
    ngrok version
}



# Call the install functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_ngrok
fi