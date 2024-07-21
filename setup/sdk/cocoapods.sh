# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/homebrew.sh"


# Function to check if CocoaPods is installed
is_cocoapods_installed() {
    if command -v pod &> /dev/null; then
        echo "CocoaPods is installed."
        return 0
    else
        echo "CocoaPods is not installed."
        return 1
    fi
}


# Function to install CocoaPods using Homebrew
install_cocoapods() {
    if ! is_cocoapods_installed; then
        
        # Ensure Homebrew is installed
        install_homebrew
        
        echo "Installing CocoaPods..."
        brew install cocoapods
        echo "CocoaPods installation completed."
    fi
}

# Export the functions for use in other scripts
export -f is_cocoapods_installed
export -f install_cocoapods

# Call the function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # install_node "$1"
    # install_node
    install_cocoapods
fi
