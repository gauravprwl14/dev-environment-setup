#!/bin/bash

# packages/apps/db/postgres.sh — Cross-platform PostgreSQL installer and service manager.
# Supports macOS (Homebrew), Debian/Ubuntu (apt + pgdg repo), Fedora/RHEL (dnf), and Arch (pacman).

source "$(dirname "${BASH_SOURCE[0]}")/../../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../lib/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../utils/update_shell_rc.sh"

# Define the PostgreSQL version
POSTGRESQL_VERSION="17"
POSTGRESQL_FORMULA="postgresql@${POSTGRESQL_VERSION}"


# Function to check if PostgreSQL is installed.
# Parameters: None
# Returns: 0 if PostgreSQL is installed, 1 otherwise
is_postgresql_installed() {
    case "$(detect_os)" in
        macos)
            if brew list "${POSTGRESQL_FORMULA}" &> /dev/null; then
                log_info "PostgreSQL is installed (${POSTGRESQL_FORMULA})."
                return 0
            else
                log_info "PostgreSQL is not installed."
                return 1
            fi
            ;;
        *)
            if command -v psql &> /dev/null; then
                log_info "PostgreSQL is installed ($(psql --version 2>/dev/null | head -1))."
                return 0
            else
                log_info "PostgreSQL is not installed."
                return 1
            fi
            ;;
    esac
}


# Function to add the PostgreSQL bin directory to PATH in the shell rc file (macOS only).
# Parameters: None
# Returns: None
add_postgresql_to_path() {
    log_step "Adding PostgreSQL to PATH..."
    local postgresql_bin_path="/opt/homebrew/opt/${POSTGRESQL_FORMULA}/bin"
    add_path_to_shell_rc "${postgresql_bin_path}"
    log_success "PostgreSQL PATH configuration completed."
}


# Function to add the PostgreSQL apt repository on Debian-based systems.
# Parameters: None
# Returns: None
_add_postgresql_apt_repo() {
    log_step "Adding PostgreSQL apt repository..."

    # Install prerequisites
    sudo apt-get install -y curl ca-certificates gnupg lsb-release

    # Add the PostgreSQL signing key
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        | sudo gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg

    # Add the pgdg repository
    local codename
    codename="$(lsb_release -cs 2>/dev/null || . /etc/os-release && echo "${VERSION_CODENAME}")"

    echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] \
https://apt.postgresql.org/pub/repos/apt ${codename}-pgdg main" \
        | sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null

    sudo apt-get update
    log_success "PostgreSQL apt repository added."
}


# Function to install PostgreSQL.
# Parameters: None
# Returns: None
install_postgresql() {
    if is_postgresql_installed; then
        log_info "PostgreSQL is already installed. Skipping installation."

        # On macOS ensure PATH is kept up to date even when skipping install.
        if [[ "$(detect_os)" == "macos" ]]; then
            add_postgresql_to_path
        fi

        return 0
    fi

    log_step "Installing PostgreSQL ${POSTGRESQL_VERSION}..."

    case "$(detect_os)" in
        macos)
            install_pkg "${POSTGRESQL_FORMULA}"
            log_success "PostgreSQL installation completed."
            add_postgresql_to_path
            start_postgresql_service
            ;;
        debian)
            _add_postgresql_apt_repo
            sudo apt-get install -y \
                "postgresql-${POSTGRESQL_VERSION}" \
                "postgresql-client-${POSTGRESQL_VERSION}"
            log_success "PostgreSQL installation completed."
            start_postgresql_service
            ;;
        fedora)
            sudo dnf install -y postgresql-server postgresql
            sudo postgresql-setup --initdb
            log_success "PostgreSQL installation completed."
            start_postgresql_service
            ;;
        arch)
            install_pkg postgresql
            log_success "PostgreSQL installation completed."
            start_postgresql_service
            ;;
        *)
            log_error "install_postgresql: unsupported OS '$(detect_os)'"
            return 1
            ;;
    esac
}


# Function to start (and enable) the PostgreSQL service.
# Parameters: None
# Returns: None
start_postgresql_service() {
    if ! is_postgresql_installed; then
        log_error "PostgreSQL is not installed. Cannot start service."
        return 1
    fi

    case "$(detect_os)" in
        macos)
            log_step "Starting PostgreSQL service (${POSTGRESQL_FORMULA})..."
            add_service "${POSTGRESQL_FORMULA}"
            ;;
        *)
            log_step "Starting PostgreSQL service (postgresql)..."
            add_service postgresql
            ;;
    esac

    log_success "PostgreSQL service started."
}


# Function to stop the PostgreSQL service.
# Parameters: None
# Returns: None
stop_postgresql_service() {
    if ! is_postgresql_installed; then
        log_error "PostgreSQL is not installed. Cannot stop service."
        return 1
    fi

    case "$(detect_os)" in
        macos)
            log_step "Stopping PostgreSQL service (${POSTGRESQL_FORMULA})..."
            stop_service "${POSTGRESQL_FORMULA}"
            ;;
        *)
            log_step "Stopping PostgreSQL service (postgresql)..."
            stop_service postgresql
            ;;
    esac

    log_success "PostgreSQL service stopped."
}


# Function to print the installed PostgreSQL client version.
# Parameters: None
# Returns: None
print_postgresql_version() {
    if command -v psql &> /dev/null; then
        log_info "PostgreSQL version:"
        psql --version
    else
        log_warn "PostgreSQL is not in PATH. Please reload your shell with: source $(get_rc_file)"
    fi
}


export -f is_postgresql_installed
export -f add_postgresql_to_path
export -f install_postgresql
export -f start_postgresql_service
export -f stop_postgresql_service
export -f print_postgresql_version


# Call the install function if this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_postgresql
fi
