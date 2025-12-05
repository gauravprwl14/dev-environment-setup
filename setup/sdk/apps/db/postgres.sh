#!/bin/bash

# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/../../homebrew.sh"
# Source the update_zshrc utility script
source "$(dirname "${BASH_SOURCE[0]}")/../../utils/update_zshrc.sh"

# Define the PostgreSQL version
POSTGRESQL_VERSION="18"
POSTGRESQL_FORMULA="postgresql@${POSTGRESQL_VERSION}"

# Function to check if PostgreSQL is installed
# Parameters: None
# Returns: 0 if PostgreSQL is installed, 1 otherwise
is_postgresql_installed() {
    if brew list "$POSTGRESQL_FORMULA" &> /dev/null; then
        echo "PostgreSQL is installed ($POSTGRESQL_FORMULA)."
        return 0
    else
        echo "PostgreSQL is not installed."
        return 1
    fi
}

# Function to add PostgreSQL to PATH in .zshrc
# Parameters: None
# Returns: None
add_postgresql_to_path() {
    echo "Adding PostgreSQL to PATH..."
    local postgresql_bin_path="/opt/homebrew/opt/${POSTGRESQL_FORMULA}/bin"
    update_zshrc "POSTGRESQL_HOME" "$postgresql_bin_path"
    echo "PostgreSQL PATH configuration completed."
}

# Function to install PostgreSQL
# Parameters: None
# Returns: None
install_postgresql() {
    # Ensure homebrew is installed
    install_homebrew

    if ! is_postgresql_installed; then
        echo "Installing PostgreSQL..."
        brew install "$POSTGRESQL_FORMULA"
        echo "PostgreSQL installation completed."

        # Add PostgreSQL to PATH
        add_postgresql_to_path

        # Start the PostgreSQL service
        start_postgresql_service
    else
        echo "PostgreSQL is already installed."
        # Ensure PATH is configured even if already installed
        add_postgresql_to_path
    fi
}

# Function to start PostgreSQL service
# Parameters: None
# Returns: None
start_postgresql_service() {
    if ! is_postgresql_installed; then
        echo "Error: PostgreSQL is not installed. Cannot start service."
        return 1
    fi
    
    echo "Starting PostgreSQL service ($POSTGRESQL_FORMULA)..."
    brew services start "$POSTGRESQL_FORMULA"
    echo "PostgreSQL service started."
}

# Function to stop PostgreSQL service
# Parameters: None
# Returns: None
stop_postgresql_service() {
    if ! is_postgresql_installed; then
        echo "Error: PostgreSQL is not installed. Cannot stop service."
        return 1
    fi
    
    echo "Stopping PostgreSQL service ($POSTGRESQL_FORMULA)..."
    brew services stop "$POSTGRESQL_FORMULA"
    echo "PostgreSQL service stopped."
}

# Function to print PostgreSQL version
# Parameters: None
# Returns: None
print_postgresql_version() {
    if command -v psql &> /dev/null; then
        echo "PostgreSQL version:"
        psql --version
    else
        echo "PostgreSQL is not in PATH. Please reload your shell with: source ~/.zshrc"
    fi
}

export -f is_postgresql_installed
export -f install_postgresql
export -f start_postgresql_service
export -f stop_postgresql_service

# Call the install functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_postgresql
fi