#!/bin/bash

# packages/apps/podman-compose.sh — Cross-platform Podman Compose installation helper.
# Supports macOS (Homebrew), Debian/Ubuntu (apt), Fedora/RHEL (dnf), and Arch (pacman).
# Podman Compose depends on Podman itself, so this script ensures Podman is
# installed first before installing the compose CLI.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/podman.sh"


# Function to check if Podman Compose is installed.
# Uses command -v so it works on all platforms regardless of package manager.
is_podman_compose_installed() {
    if command -v podman-compose &> /dev/null; then
        log_success "Podman Compose is installed."
        return 0
    else
        log_info "Podman Compose is not installed."
        return 1
    fi
}


# Function to install Podman Compose for the current platform.
# Ensures Podman itself is installed first, since podman-compose is a thin
# orchestration layer on top of the podman CLI.
install_podman_compose() {
    local os
    os="$(detect_os)"

    # Podman Compose requires Podman — install it first if missing.
    install_podman

    if is_podman_compose_installed; then
        log_success "Podman Compose is already installed. Skipping."
        return 0
    fi

    case "${os}" in
        macos)
            log_step "Installing Podman Compose via Homebrew..."
            install_pkg podman-compose
            log_success "Podman Compose installation completed."
            ;;
        debian)
            log_step "Installing Podman Compose via apt..."
            install_pkg podman-compose
            log_success "Podman Compose installation completed."
            ;;
        fedora)
            log_step "Installing Podman Compose via dnf..."
            install_pkg podman-compose
            log_success "Podman Compose installation completed."
            ;;
        arch)
            log_step "Installing Podman Compose via pacman..."
            install_pkg podman-compose
            log_success "Podman Compose installation completed."
            ;;
        *)
            log_error "install_podman_compose: unsupported OS '${os}'"
            return 1
            ;;
    esac

    # Fallback: some distro repos (older Debian/Ubuntu) don't ship
    # podman-compose. If the binary still isn't on PATH, fall back to pipx/pip.
    if ! is_podman_compose_installed; then
        log_warn "podman-compose not found via package manager, falling back to pip install --user."
        if command -v pipx &> /dev/null; then
            pipx install podman-compose
        elif command -v pip3 &> /dev/null; then
            pip3 install --user podman-compose
        else
            log_error "Neither pipx nor pip3 found — cannot install podman-compose as a fallback."
            return 1
        fi
        log_success "Podman Compose installation completed via pip fallback."
    fi
}


# Function to print the installed Podman Compose version.
print_podman_compose_version() {
    if is_podman_compose_installed; then
        log_info "Podman Compose version:"
        podman-compose --version
    else
        log_warn "Podman Compose is not installed yet."
    fi
}


export -f is_podman_compose_installed
export -f install_podman_compose
export -f print_podman_compose_version


# Run install and version check when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_podman_compose
    print_podman_compose_version
fi
