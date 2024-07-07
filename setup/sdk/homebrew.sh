#!/bin/bash

# Source the update_zshrc.sh script
source ./utils/update_zshrc.sh


# Function to check if Homebrew is installed
# Parameters: None
# Returns: 0 if Homebrew is installed, 1 otherwise
is_homebrew_installed() {
    if command -v brew &> /dev/null; then
        return 0
    else
        return 1
    fi
}


# Function to install Homebrew
# Parameters: None
# Returns: None

install_homebrew() {
    
if ! is_homebrew_installed; then
    echo "Homebrew is not installed. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

else
    echo "Homebrew is already installed. Updating Homebrew..."

    # Update Homebrew
    brew update

fi


# Define Homebrew path
HOMEBREW_VARIABLE_NAME="HOMEBREW"
HOMEBREW_VARIABLE_VALUE="/opt/homebrew/bin"

 # Call the update_zshrc function, passing only the Homebrew path
update_zshrc "$HOMEBREW_VARIABLE_NAME" "$HOMEBREW_VARIABLE_VALUE"


}

# Call the install_homebrew function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_homebrew
fi


# Export the functions for use in other scripts
export -f is_homebrew_installed
export -f install_homebrew

