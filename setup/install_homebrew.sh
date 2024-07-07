#!/bin/bash

# Source the update_zshrc.sh script
source ./utils/update_zshrc.sh

if ! command -v brew &> /dev/null; then
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

