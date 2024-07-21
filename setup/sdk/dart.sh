#!/bin/bash
# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/homebrew.sh"



# Function to check if DART is installed
is_dart_installed() {
    if command -v dart &> /dev/null; then
        echo "Dart is installed."
        return 0
    else
        echo "Dart is not installed."
        return 1
    fi
}

# Function to install Dart using Homebrew
install_dart() {
    if ! is_dart_installed; then
        echo "Installing dart..."
        
        brew tap dart-lang/dart
        brew install dart
        
        echo "dart installation completed."

        update_dart_zshrc

        activate_fvm
    else
        echo "dart is already installed."
    fi
}

activate_fvm() {
    echo "Activating FVM..."
    
    dart pub global activate fvm
}

update_dart_zshrc() {
    local dart_path="$(brew --prefix dart)/bin"
    update_zshrc "DART_HOME" "$dart_path"

    pub_cache_path='$HOME/.pub-cache/bin'
    update_zshrc "PUB_CACHE_PATH" "$pub_cache_path"
}



# Call the install_homebrew function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_dart
fi


export -f is_dart_installed
export -f install_dart
