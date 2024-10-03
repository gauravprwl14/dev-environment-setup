#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"

# Function to check if Redis is installed
is_redis_installed() {
    if command -v redis-server &> /dev/null
    then
        return 0
    else
        return 1
    fi
}

# Function to install Redis using Homebrew
install_redis() {
    if ! is_redis_installed; then 
        # Ensure homebrew is installed
        install_homebrew
        
        echo "Redis is not installed. Installing..."
        brew install redis
        
        if [ $? -eq 0 ]; then
            echo "Redis installed successfully."
        else
            echo "Failed to install Redis."
            exit 1
        fi
    fi
}

# Function to print the Redis version
print_redis_version() {
    echo "Redis version:"
    redis-server --version
}

# Call the install functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_redis
fi
