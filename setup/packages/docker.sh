#!/bin/bash

# packages/docker.sh — Cross-platform Docker installation script.
# Supports macOS (Docker Desktop via Homebrew Cask), Debian-based, Fedora-based,
# and Arch Linux distributions.

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"


# is_docker_installed
# Returns 0 if the docker binary is found on PATH, 1 otherwise.
is_docker_installed() {
    if command -v docker &> /dev/null; then
        log_info "Docker is installed."
        return 0
    else
        log_info "Docker is not installed."
        return 1
    fi
}


# install_docker
# Installs Docker using the appropriate method for the current OS:
#   macOS   : Docker Desktop via Homebrew Cask
#   Debian  : Docker's official GPG key + apt repo, then docker-ce packages
#   Fedora  : Docker's official repo via dnf config-manager, then docker-ce packages
#   Arch    : docker package via pacman
# On Linux, the Docker service is enabled and started, and the current user is
# added to the docker group.
install_docker() {
    if is_docker_installed; then
        log_success "Docker is already installed. Skipping."
        return 0
    fi

    local os
    os="$(detect_os)"

    log_step "Installing Docker (OS: ${os})"

    case "${os}" in
        macos)
            log_info "Installing Docker Desktop via Homebrew Cask..."
            install_cask docker
            log_success "Docker Desktop installation completed."
            ;;

        debian)
            log_info "Adding Docker's official GPG key and apt repository..."

            sudo apt-get update -y
            sudo apt-get install -y ca-certificates curl gnupg

            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
                | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg

            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
                | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            sudo apt-get update -y

            log_info "Installing docker-ce packages..."
            sudo apt-get install -y \
                docker-ce \
                docker-ce-cli \
                containerd.io \
                docker-buildx-plugin \
                docker-compose-plugin

            log_info "Enabling and starting Docker service..."
            sudo systemctl enable --now docker

            log_info "Adding current user (${USER}) to the docker group..."
            sudo usermod -aG docker "${USER}"

            log_success "Docker installation completed."
            log_warn "Log out and back in (or run 'newgrp docker') for the group change to take effect."
            ;;

        fedora)
            log_info "Adding Docker's official repository via dnf config-manager..."

            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager --add-repo \
                https://download.docker.com/linux/fedora/docker-ce.repo

            log_info "Installing docker-ce packages..."
            sudo dnf install -y \
                docker-ce \
                docker-ce-cli \
                containerd.io \
                docker-buildx-plugin \
                docker-compose-plugin

            log_info "Enabling and starting Docker service..."
            sudo systemctl enable --now docker

            log_info "Adding current user (${USER}) to the docker group..."
            sudo usermod -aG docker "${USER}"

            log_success "Docker installation completed."
            log_warn "Log out and back in (or run 'newgrp docker') for the group change to take effect."
            ;;

        arch)
            log_info "Installing Docker via pacman..."
            install_pkg docker

            log_info "Enabling and starting Docker service..."
            sudo systemctl enable --now docker

            log_info "Adding current user (${USER}) to the docker group..."
            sudo usermod -aG docker "${USER}"

            log_success "Docker installation completed."
            log_warn "Log out and back in (or run 'newgrp docker') for the group change to take effect."
            ;;

        *)
            log_error "install_docker: unsupported OS '${os}'"
            return 1
            ;;
    esac
}


# start_docker
# Starts the Docker daemon / application for the current OS:
#   macOS : opens Docker Desktop via 'open'
#   Linux : starts the Docker daemon via systemctl
start_docker() {
    local os
    os="$(detect_os)"

    log_step "Starting Docker (OS: ${os})"

    case "${os}" in
        macos)
            log_info "Opening Docker Desktop..."
            open /Applications/Docker.app
            log_success "Docker Desktop launched."
            ;;
        debian|fedora|arch|linux)
            log_info "Starting Docker daemon via systemctl..."
            sudo systemctl start docker
            log_success "Docker daemon started."
            ;;
        *)
            log_error "start_docker: unsupported OS '${os}'"
            return 1
            ;;
    esac
}


# print_docker_version
# Prints the installed Docker client version.
print_docker_version() {
    log_info "Docker version:"
    docker --version
}


export -f is_docker_installed
export -f install_docker
export -f start_docker
export -f print_docker_version


# Run install_docker when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_docker
fi
