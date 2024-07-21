#!/bin/bash
# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/homebrew.sh"


DEFAULT_FVM_DIR='$HOME/fvm'

# Function to check if FVM is installed
is_fvm_installed() {
    if command -v fvm &> /dev/null; then
        echo "FVM is installed."
        return 0
    else
        echo "FVM is not installed."
        return 1
    fi
}

# Function to install FVM using Homebrew
install_fvm() {
    if ! is_fvm_installed; then
        echo "Installing FVM..."
        brew tap leoafarias/fvm
        brew install fvm
        echo "FVM installation completed."

        update_fvm_zshrc
    else
        echo "FVM is already installed."
    fi
}

# Function to configure FVM to use a specific directory
update_fvm_zshrc() {
    mkdir -p "$DEFAULT_FVM_DIR"

    # local zshrc_path="${1:-$HOME/.zshrc}"
    # update_exported_variable "FVM_HOME" "$DEFAULT_FVM_DIR"
    
    local fvm_path='$HOME/fvm/default/bin'
    update_zshrc "FVM_CACHE_PATH" "$fvm_path"

    export FVM_HOME="$DEFAULT_FVM_DIR"
}


# Call the install_homebrew function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_fvm
fi


export -f is_fvm_installed
export -f install_fvm
