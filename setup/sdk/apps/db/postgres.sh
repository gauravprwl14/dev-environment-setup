#!/bin/bash


# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/../../homebrew.sh"

# Function to check if PostgreSQL is installed
is_postgresql_installed() {
    if brew list postgresql &> /dev/null; then
        echo "PostgreSQL is installed."
        return 0
    else
        echo "PostgreSQL is not installed."
        return 1
    fi
}

# Function to install PostgreSQL
install_postgresql() {
    
    # Ensure homebrew is installed
    install_homebrew

    if ! is_postgresql_installed; then
        echo "Installing PostgreSQL..."
        brew install postgresql
        
        # brew install postgresql@15 # to install a specific version
        echo "PostgreSQL installation completed."

        # Start the PostgreSQL service
        start_postgresql_service
    fi
}

# Function to start PostgreSQL service
start_postgresql_service() {
    echo "Starting PostgreSQL service..."
    brew services start postgresql
    # brew services start postgresql@15 # to start a specific version
    echo "PostgreSQL service started."
}
# Function to stop PostgreSQL service
stop_postgresql_service() {
    echo "Starting PostgreSQL service..."
    brew services stop postgresql
    # brew services stop postgresql@15 # to start a specific version
    echo "PostgreSQL service started."
}


# Function to print PostgreSQL version
print_postgresql_version() {
    echo "PostgreSQL version:"
    psql --version
}

export -f is_postgresql_installed
export -f install_postgresql


# Call the install functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_postgresql
fi