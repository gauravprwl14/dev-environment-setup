#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/homebrew.sh"
source "$(dirname "${BASH_SOURCE[0]}")/nvm.sh"


# Function to check if Node.js is installed
# Parameters: 
#   $1 - Node.js version to check (optional, default: stable)
# Returns: 0 if Node.js is installed, 1 otherwise

is_node_installed() {
    local node_version="${1:-stable}"
    if is_nvm_installed; then
        if nvm ls "$node_version" &> /dev/null; then
            echo "Node.js version $node_version is installed."
            return 0
        else
            echo "Node.js version $node_version is not installed."
            return 1
        fi
    else
        echo "nvm is not installed."
        return 1
    fi
}

# Function to install Node.js
# Parameters: 
#   $1 - Node.js version to install (optional, default: stable)
# Returns: None
install_node() {
    local node_version="${1:-stable}"

    # Ensure Homebrew is installed
    install_homebrew

    # Ensure NVM is installed
    install_nvm

    # # Ensure nvm is installed
    # if ! command -v nvm &> /dev/null; then
    #     echo "nvm not found, installing..."
    #     brew install nvm
    #     mkdir -p ~/.nvm
    #     echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
    #     echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"' >> ~/.zshrc
    #     source ~/.zshrc
    # fi

    # Check if the specified version of Node.js is already installed
    if is_node_installed "$node_version"; then
        echo "Node.js version $node_version is already installed."
    else
        echo "Installing Node.js version $node_version..."
        nvm install "$node_version"
        nvm use "$node_version"
        nvm alias default "$node_version"
        echo "Node.js version $node_version installation complete."

        # Install Yarn, Next.js, Expo CLI, and React Native CLI

        install_node_tools
    fi
}

# Function to install Yarn, Next.js, Expo CLI, and React Native CLI
install_node_tools() {
    echo "Installing Yarn..."
    brew install yarn
    echo "Yarn installation completed."

    echo "Installing Next.js..."
    yarn global add next
    echo "Next.js installation completed."


    echo "Installing React Native CLI..."
    yarn global add react-native-cli
    echo "React Native CLI installation completed."
}

# Export the functions for use in other scripts
export -f is_node_installed
export -f install_node

# Call the function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # install_node "$1"
    install_node
    install_node_tools
fi
