#!/bin/bash

# mysql.sh — Cross-platform MySQL installation and service management.
# Supports macOS (Homebrew), Debian-based, Fedora-based, and Arch Linux.

source "$(dirname "${BASH_SOURCE[0]}")"/../../../lib/detect_os.sh
source "$(dirname "${BASH_SOURCE[0]}")"/../../../lib/pkg.sh
source "$(dirname "${BASH_SOURCE[0]}")"/../../../lib/logger.sh


# is_mysql_installed
# Returns 0 if the mysql binary is found on PATH, 1 otherwise.
is_mysql_installed() {
    if command -v mysql &> /dev/null; then
        log_info "MySQL is installed."
        return 0
    else
        log_info "MySQL is not installed."
        return 1
    fi
}


# install_mysql
# Installs MySQL via the appropriate package manager for the current OS and
# starts the service afterwards.
install_mysql() {
    if is_mysql_installed; then
        log_warn "MySQL is already installed. Skipping installation."
        return 0
    fi

    log_step "Installing MySQL..."

    case "$(detect_os)" in
        macos)
            install_pkg mysql
            ;;
        debian)
            install_pkg mysql-server
            sudo systemctl enable --now mysql
            ;;
        fedora)
            install_pkg mysql-server
            sudo systemctl enable --now mysqld
            ;;
        arch)
            if install_pkg mysql; then
                log_info "MySQL installed via pacman."
            else
                log_warn "mysql not found in pacman repositories; falling back to mariadb."
                install_pkg mariadb
            fi
            ;;
        *)
            log_error "install_mysql: unsupported OS '$(detect_os)'"
            return 1
            ;;
    esac

    log_success "MySQL installation completed."
    start_mysql_service
}


# start_mysql_service
# Enables and starts the MySQL service using the pkg.sh add_service helper.
# The service name differs per OS: mysql on macOS/Debian, mysqld on Fedora,
# and mysql (or mariadb if installed instead) on Arch.
start_mysql_service() {
    log_step "Starting MySQL service..."

    case "$(detect_os)" in
        macos)
            add_service mysql
            ;;
        debian)
            add_service mysql
            ;;
        fedora)
            add_service mysqld
            ;;
        arch)
            if command -v mysqld &> /dev/null; then
                add_service mysqld
            else
                add_service mysql
            fi
            ;;
        *)
            log_error "start_mysql_service: unsupported OS '$(detect_os)'"
            return 1
            ;;
    esac

    log_success "MySQL service started."
}


# stop_mysql_service
# Stops the MySQL service using the pkg.sh stop_service helper.
stop_mysql_service() {
    log_step "Stopping MySQL service..."

    case "$(detect_os)" in
        macos)
            stop_service mysql
            ;;
        debian)
            stop_service mysql
            ;;
        fedora)
            stop_service mysqld
            ;;
        arch)
            if command -v mysqld &> /dev/null; then
                stop_service mysqld
            else
                stop_service mysql
            fi
            ;;
        *)
            log_error "stop_mysql_service: unsupported OS '$(detect_os)'"
            return 1
            ;;
    esac

    log_success "MySQL service stopped."
}


# print_mysql_version
# Prints the installed MySQL version string.
print_mysql_version() {
    log_info "MySQL version:"
    mysql --version
}


export -f is_mysql_installed
export -f install_mysql
export -f start_mysql_service
export -f stop_mysql_service
export -f print_mysql_version


# Run install_mysql if this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_mysql
fi
