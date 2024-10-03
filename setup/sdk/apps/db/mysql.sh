# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/../../homebrew.sh"

#!/bin/bash


# Function to check if MySQL is installed
is_mysql_installed() {
    if brew list mysql &> /dev/null; then
        echo "MySQL is installed."
        return 0
    else
        echo "MySQL is not installed."
        return 1
    fi
}

# Function to install MySQL
install_mysql() {
    # Ensure homebrew is installed
    install_homebrew

    if ! is_mysql_installed; then
        echo "Installing MySQL..."
        brew install mysql
        
        # brew install mysql@5.7 # to install a specific version
        echo "MySQL installation completed."

        # Start the MySQL service
        start_mysql_service
    fi
}

# Function to start MySQL service
start_mysql_service() {
    echo "Starting MySQL service..."
    brew services start mysql
    # brew services start mysql@5.7 # to start a specific version
    echo "MySQL service started."
}

# Function to stop MySQL service
stop_mysql_service() {
    echo "Stopping MySQL service..."
    brew services stop mysql
    # brew services stop mysql@5.7 # to stop a specific version
    echo "MySQL service stopped."
}

# Function to print MySQL version
print_mysql_version() {
    echo "MySQL version:"
    mysql --version
}

export -f is_mysql_installed
export -f install_mysql

# Call the install functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_mysql
fi






# # Function to check if PostgreSQL is installed
# is_postgresql_installed() {
#     if brew list postgresql &> /dev/null; then
#         echo "PostgreSQL is installed."
#         return 0
#     else
#         echo "PostgreSQL is not installed."
#         return 1
#     fi
# }

# # Function to install PostgreSQL
# install_postgresql() {
    
#     # Ensure homebrew is installed
#     install_homebrew

#     if ! is_postgresql_installed; then
#         echo "Installing PostgreSQL..."
#         brew install postgresql
        
#         # brew install postgresql@15 # to install a specific version
#         echo "PostgreSQL installation completed."

#         # Start the PostgreSQL service
#         start_postgresql_service
#     fi
# }

# # Function to start PostgreSQL service
# start_postgresql_service() {
#     echo "Starting PostgreSQL service..."
#     brew services start postgresql
#     # brew services start postgresql@15 # to start a specific version
#     echo "PostgreSQL service started."
# }
# # Function to stop PostgreSQL service
# stop_postgresql_service() {
#     echo "Starting PostgreSQL service..."
#     brew services stop postgresql
#     # brew services stop postgresql@15 # to start a specific version
#     echo "PostgreSQL service started."
# }


# # Function to print PostgreSQL version
# print_postgresql_version() {
#     echo "PostgreSQL version:"
#     psql --version
# }

# export -f is_postgresql_installed
# export -f install_postgresql


