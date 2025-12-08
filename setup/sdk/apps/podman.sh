#!/bin/bash
# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/../homebrew.sh"


# Function to check if Podman is installed
is_podman_installed() {
    if brew list podman &> /dev/null; then
        echo "Podman is installed."
        return 0
    else
        echo "Podman is not installed."
        return 1
    fi
}

# Function to check if Podman machine is initialized
is_podman_machine_initialized() {
    if podman machine list --format "{{.Name}}" | grep -q "^podman$"; then
        echo "Podman machine is initialized."
        return 0
    else
        echo "Podman machine is not initialized."
        return 1
    fi
}

# Function to check if Podman machine is running
is_podman_machine_running() {
    if podman machine list --format "{{.Running}}" | grep -q "true"; then
        echo "Podman machine is running."
        return 0
    else
        echo "Podman machine is not running."
        return 1
    fi
}

# Function to install Podman
install_podman() {
    if ! is_podman_installed; then
        # Ensure homebrew is installed
        install_homebrew

        echo "Installing Podman..."
        brew install podman
        echo "Podman installation completed."
    fi

    # Initialize Podman machine if not already initialized
    if ! is_podman_machine_initialized; then
        echo "Initializing Podman machine..."
        podman machine init
        echo "Podman machine initialization completed."
    fi

    # Start Podman machine if not running
    if ! is_podman_machine_running; then
        echo "Starting Podman machine..."
        podman machine start
        echo "Podman machine started."
    fi
}

# Function to print Podman version
print_podman_version() {
    if is_podman_installed; then
        echo "Podman version:"
        podman --version
    else
        echo "Podman is not installed yet."
    fi
}


export -f is_podman_installed
export -f is_podman_machine_initialized
export -f is_podman_machine_running
export -f install_podman
export -f print_podman_version


# Call the install functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_podman
    print_podman_version
fi
