#!/bin/bash
# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/homebrew.sh"


# Function to check if Docker is installed
is_docker_installed() {
    if brew list --cask docker &> /dev/null; then
        echo "Docker is installed."
        return 0
    else
        echo "Docker is not installed."
        return 1
    fi
}


# Function to install Docker
install_docker() {
    
    
    if ! is_docker_installed; then
        
        # Ensure homebrew is installed
        install_homebrew


        echo "Installing Docker..."
        brew install --cask docker
        echo "Docker installation completed."
    fi
}

# Function to start Docker
start_docker() {
    echo "Starting Docker..."
    open /Applications/Docker.app
    echo "Docker started."
}

# Function to print Docker version
print_docker_version() {
    echo "Docker version:"
    docker --version
}


export -f is_docker_installed
export -f install_docker


# Call the install functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    print_docker_version
fi
