#!/bin/bash

# packages/apps/redis.sh — Cross-platform Redis installation helper.
# Supports macOS (Homebrew), Debian/Ubuntu (apt), Fedora/RHEL (dnf), and Arch (pacman).
# On Linux, the Redis service is enabled and started via systemctl after installation.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"


# Function to check if Redis is installed.
# Uses command -v so it works on all platforms regardless of package manager.
is_redis_installed() {
    if command -v redis-server &> /dev/null; then
        log_success "Redis is installed."
        return 0
    else
        log_info "Redis is not installed."
        return 1
    fi
}


# Function to install Redis for the current platform.
# On Linux (debian/fedora/arch), also enables and starts the Redis service via systemctl.
install_redis() {
    local os
    os="$(detect_os)"

    if ! is_redis_installed; then
        case "${os}" in
            macos)
                log_step "Installing Redis via Homebrew..."
                install_pkg redis
                log_success "Redis installation completed."
                ;;
            debian)
                log_step "Installing Redis via apt..."
                install_pkg redis
                log_success "Redis installation completed."
                add_service redis
                ;;
            fedora)
                log_step "Installing Redis via dnf..."
                install_pkg redis
                log_success "Redis installation completed."
                add_service redis
                ;;
            arch)
                log_step "Installing Redis via pacman..."
                install_pkg redis
                log_success "Redis installation completed."
                add_service redis
                ;;
            *)
                log_error "install_redis: unsupported OS '${os}'"
                return 1
                ;;
        esac
    fi
}


# Function to enable and start the Redis service.
#   macOS : brew services start redis
#   Linux : systemctl enable --now redis
start_redis_service() {
    log_step "Starting Redis service..."
    add_service redis
    log_success "Redis service started."
}


# Function to stop the running Redis service.
#   macOS : brew services stop redis
#   Linux : systemctl stop redis
stop_redis_service() {
    log_step "Stopping Redis service..."
    stop_service redis
    log_success "Redis service stopped."
}


# Function to print the installed Redis server version.
print_redis_version() {
    if is_redis_installed; then
        log_info "Redis version:"
        redis-server --version
    else
        log_warn "Redis is not installed yet."
    fi
}


export -f is_redis_installed
export -f install_redis
export -f start_redis_service
export -f stop_redis_service
export -f print_redis_version


# Run install and version check when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_redis
    print_redis_version
fi
