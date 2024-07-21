#!/bin/bash
# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/homebrew.sh"
source "$(dirname "${BASH_SOURCE[0]}")/cocoapods.sh"
source "$(dirname "${BASH_SOURCE[0]}")/fvm.sh"


# Function to check if Flutter is installed
is_flutter_installed() {
    if command -v flutter &> /dev/null; then
        echo "Flutter is installed."
        return 0
    else
        echo "Flutter is not installed."
        return 1
    fi
}

# Function to install Flutter using Homebrew
install_flutter() {
    if ! is_flutter_installed; then
        
        # Ensure Rosetta 2 is installed
        install_rosetta
        
        # Ensure CocoaPods is installed
        install_cocoapods
        
        echo "checking FMV..."
        install_fvm
        
        echo "Installing FLutter..."
        install_flutter_with_fvm

        print_flutter_version
        
        # brew install --cask flutter
        echo "Flutter installation completed."
    fi
}



# Function to install Flutter using FVM
install_flutter_with_fvm() {
    
    if is_fvm_installed; then 
        
        configure_flutter_directory

        echo "Installing Flutter using FVM..."
        fvm install stable
        fvm use stable

        fvm flutter --version

        update_flutter_zshrc

        echo "Flutter installation with FVM completed."
    else 
       echo "FVM is not installed. Please install FVM before installing Flutter." 
       
    fi
    
}

configure_flutter_directory() {
    # Create .fvm folder in the home directory
    mkdir -p "$HOME/.fvm"
    
    # Change directory to home
    echo "Changing directory to $HOME"
    cd "$HOME"
}


# Function to update .zshrc with the Flutter path
update_flutter_zshrc() {
    # Add Flutter to PATH in .zshrc
    # echo 'export PATH="$PATH:/opt/homebrew/opt/flutter/bin"' >> ~/.zshrc
    $flutter_path_value="\$HOME/.fvm/default/bin"
    update_zshrc "FLUTTER_HOME" "$flutter_path_value"
}

# Function to install Rosetta 2 if not already installed
install_rosetta() {
    if [[ $(uname -p) == 'arm' ]]; then
        echo "Checking for Rosetta 2..."
        if ! /usr/bin/pgrep oahd > /dev/null 2>&1; then
            echo "Rosetta 2 is not installed. Installing..."
            sudo softwareupdate --install-rosetta --agree-to-license
            echo "Rosetta 2 installation completed."
        else
            echo "Rosetta 2 is already installed."
        fi
    else
        echo "Rosetta 2 installation is not required for Intel Macs."
    fi
}



# Function to print Flutter version
print_flutter_version() {
    # Print Flutter version
    echo "Flutter version:"
    flutter --version
}


export -f is_flutter_installed
export -f install_flutter


# Call the install functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_flutter
fi


# ToDO: Add the following to the .zshrc file
# fvm global stable
# check the fvm directory => ~/fvm vs ~/.fvm vs ~/.fvm/default/bin vs ~/.fvm/default/bin/default/bin
# check the fvm directory variable names => PUB_CACHE_PATH vs FVM_CACHE_PATH vs FVM_HOME vs Flutter_HOME
# https://cshanjib.medium.com/setting-up-fvm-flutter-version-management-properly-ab45ade0dd55