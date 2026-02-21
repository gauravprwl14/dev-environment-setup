#!/bin/bash

# packages/apps/db/mongodb.sh — Cross-platform MongoDB installation helper.
#
# Installs MongoDB Community Edition ${MONGODB_VERSION} and manages its service.
#
# Platform support:
#   macOS          : Homebrew (mongodb/brew tap + mongodb-community)
#   Debian/Ubuntu  : Official MongoDB apt repository (Ubuntu 22.04 / 24.04)
#   Fedora/RHEL    : Official MongoDB yum/dnf repository
#   Arch           : AUR package mongodb-bin via install_cask

source "$(dirname "${BASH_SOURCE[0]}")/../../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../lib/logger.sh"


MONGODB_VERSION="8.0"


# Function to check if MongoDB is installed.
# Uses command -v mongod so it works on all platforms regardless of package manager.
# Parameters: None
# Returns: 0 if mongod is found on PATH, 1 otherwise
is_mongodb_installed() {
    if command -v mongod &> /dev/null; then
        log_success "MongoDB is installed."
        return 0
    else
        log_info "MongoDB is not installed."
        return 1
    fi
}


# Function to add the official MongoDB apt repository for Debian/Ubuntu systems.
# Targets Ubuntu 22.04 (jammy) and 24.04 (noble); defaults to jammy for other releases.
# Parameters: None
# Returns: 0 on success, non-zero on failure
_add_mongodb_apt_repo() {
    local ubuntu_codename
    ubuntu_codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME}}")"

    # MongoDB ${MONGODB_VERSION} supports jammy (22.04) and noble (24.04).
    case "${ubuntu_codename}" in
        noble)
            ;;
        jammy)
            ;;
        *)
            log_warn "_add_mongodb_apt_repo: unrecognised codename '${ubuntu_codename}', defaulting to jammy."
            ubuntu_codename="jammy"
            ;;
    esac

    log_info "Adding MongoDB apt repository for Ubuntu ${ubuntu_codename}..."

    # Import the MongoDB GPG signing key.
    curl -fsSL "https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc" \
        | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg

    # Add the MongoDB repository entry.
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg ] \
https://repo.mongodb.org/apt/ubuntu ${ubuntu_codename}/mongodb-org/${MONGODB_VERSION} multiverse" \
        | sudo tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list > /dev/null

    sudo apt-get update
}


# Function to add the official MongoDB yum repository for Fedora/RHEL systems.
# Parameters: None
# Returns: 0 on success, non-zero on failure
_add_mongodb_yum_repo() {
    log_info "Adding MongoDB yum repository..."

    sudo tee /etc/yum.repos.d/mongodb-org-${MONGODB_VERSION}.repo > /dev/null <<EOF
[mongodb-org-${MONGODB_VERSION}]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/${MONGODB_VERSION}/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc
EOF
}


# Function to install MongoDB for the current platform.
#   macOS          : brew tap mongodb/brew, then install mongodb-community
#   Debian/Ubuntu  : add MongoDB apt repo, install mongodb-org
#   Fedora/RHEL    : add MongoDB yum repo, install mongodb-org
#   Arch           : install mongodb-bin from the AUR via install_cask
# Parameters: None
# Returns: 0 on success, 1 on unsupported OS or install failure
install_mongodb() {
    local os
    os="$(detect_os)"

    if is_mongodb_installed; then
        log_success "MongoDB is already installed. Skipping."
        return 0
    fi

    log_step "Installing MongoDB ${MONGODB_VERSION}..."

    case "${os}" in
        macos)
            log_info "Tapping mongodb/brew..."
            brew tap mongodb/brew
            install_pkg mongodb-community
            ;;
        debian)
            _add_mongodb_apt_repo
            install_pkg mongodb-org
            ;;
        fedora)
            _add_mongodb_yum_repo
            install_pkg mongodb-org
            ;;
        arch)
            install_cask mongodb-bin
            ;;
        *)
            log_error "install_mongodb: unsupported OS '${os}'."
            return 1
            ;;
    esac

    log_success "MongoDB ${MONGODB_VERSION} installation completed."
}


# Function to enable and start the mongod service.
#   macOS  : brew services start mongod
#   Linux  : systemctl enable --now mongod
# Parameters: None
# Returns: 0 on success, non-zero on failure
start_mongodb_service() {
    log_step "Starting MongoDB service..."
    add_service mongod
    log_success "MongoDB service started."
}


# Function to stop the running mongod service.
#   macOS  : brew services stop mongod
#   Linux  : systemctl stop mongod
# Parameters: None
# Returns: 0 on success, non-zero on failure
stop_mongodb_service() {
    log_step "Stopping MongoDB service..."
    stop_service mongod
    log_success "MongoDB service stopped."
}


# Function to print the installed mongod version.
# Parameters: None
# Returns: None
print_mongodb_version() {
    if is_mongodb_installed; then
        log_info "MongoDB version:"
        mongod --version
    else
        log_warn "MongoDB is not installed yet."
    fi
}


export -f is_mongodb_installed
export -f _add_mongodb_apt_repo
export -f _add_mongodb_yum_repo
export -f install_mongodb
export -f start_mongodb_service
export -f stop_mongodb_service
export -f print_mongodb_version


# Run install, start service, and print version when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_mongodb
    start_mongodb_service
    print_mongodb_version
fi
