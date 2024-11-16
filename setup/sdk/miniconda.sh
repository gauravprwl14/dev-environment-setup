#!/bin/bash

# Source the Homebrew script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/homebrew.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/update_zshrc.sh"

DEFAULT_CONDA_SECTION_START="# Start MINICONDA section"
DEFAULT_CONDA_SECTION_END="# End MINICONDA section"
DEFAULT_MINICONDA_INSTALL_PATH='$HOME/miniconda3'

# Function to check if Homebrew is installed
is_homebrew_installed() {
    if command -v brew &>/dev/null; then
        echo "Homebrew is installed."
        return 0
    else
        echo "Homebrew is not installed."
        return 1
    fi
}

# Function to check if Miniconda is installed
is_miniconda_installed() {
    if [ -d "$DEFAULT_MINICONDA_INSTALL_PATH" ]; then
        echo "Miniconda is installed."
        return 0
    else
        echo "Miniconda is not installed."
        return 1
    fi
}

# Function to install Miniconda using Homebrew
install_miniconda() {
    # Ensure Homebrew is installed
    install_homebrew

    if ! is_miniconda_installed; then
        echo "Installing Miniconda using Homebrew..."
        brew install --cask miniconda

        # Ensure Miniconda's path is added to .zshrc
        update_miniconda_zshrc
        
        # Initialize Miniconda in .zshrc
        initialize_conda_in_zshrc

        echo "Miniconda installation completed."
    else
        echo "Miniconda is already installed."
    fi
}

# Function to update .zshrc with the Miniconda path
update_miniconda_zshrc() {
    echo "Updating .zshrc with Miniconda path..."
    # Add Miniconda to PATH in .zshrc
    miniconda_path_value="$DEFAULT_MINICONDA_INSTALL_PATH/bin"
    update_zshrc "MINICONDA_HOME" "$miniconda_path_value"
}

# Function to initialize Miniconda in .zshrc
initialize_miniconda_in_zshrc() {
    echo "Initializing Miniconda in .zshrc..."
    # Add Miniconda's initialization command within the defined section
    if grep -q "$DEFAULT_CONDA_SECTION_START" "$DEFAULT_ZSHRC_PATH" && grep -q "$DEFAULT_CONDA_SECTION_END" "$DEFAULT_ZSHRC_PATH"; then
        sed -i '' "/$DEFAULT_CONDA_SECTION_START/,/$DEFAULT_CONDA_SECTION_END/{ /$DEFAULT_CONDA_SECTION_START/{p; a\\
        source \"$DEFAULT_MINICONDA_INSTALL_PATH/etc/profile.d/conda.sh\"
        }; }" "$DEFAULT_ZSHRC_PATH"
        echo "Miniconda initialization added within the existing section in $DEFAULT_ZSHRC_PATH."
    else
        {
            echo "$DEFAULT_CONDA_SECTION_START"
            echo "source \"$DEFAULT_MINICONDA_INSTALL_PATH/etc/profile.d/conda.sh\""
            echo "$DEFAULT_CONDA_SECTION_END"
        } >>"$DEFAULT_ZSHRC_PATH"
        echo "Miniconda initialization section added to $DEFAULT_ZSHRC_PATH."
    fi
}

# Function to check if `conda` command works
verify_conda_installation() {
    if command -v conda &>/dev/null; then
        echo "Miniconda installed successfully: $(conda --version)"
        return 0
    else
        echo "Error: 'conda' command not found. Check your Miniconda installation."
        return 1
    fi
}

# Function to clean up the script environment
cleanup() {
    echo "Cleanup completed."
}

# Export functions for use in other scripts
export -f is_homebrew_installed
export -f install_homebrew
export -f is_miniconda_installed
export -f install_miniconda
export -f initialize_conda_in_zshrc
export -f verify_conda_installation

# Execute the script logic if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # install_miniconda
    # verify_conda_installation
    update_miniconda_zshrc
    initialize_miniconda_in_zshrc
fi