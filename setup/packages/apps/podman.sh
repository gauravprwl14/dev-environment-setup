#!/bin/bash

# packages/apps/podman.sh — Cross-platform Podman installation helper.
# Supports macOS (Homebrew), Debian/Ubuntu (apt), Fedora/RHEL (dnf), and Arch (pacman).
# On macOS, Podman requires a lightweight VM (podman machine); on Linux it runs natively.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"


# Function to check if Podman is installed.
# Uses command -v so it works on all platforms regardless of package manager.
is_podman_installed() {
    if command -v podman &> /dev/null; then
        log_success "Podman is installed."
        return 0
    else
        log_info "Podman is not installed."
        return 1
    fi
}


# Function to check if the Podman machine has been initialized.
# macOS only — on Linux, Podman runs natively without a VM.
is_podman_machine_initialized() {
    if podman machine list --format "{{.Name}}" 2>/dev/null | grep -q "^podman$"; then
        log_success "Podman machine is initialized."
        return 0
    else
        log_info "Podman machine is not initialized."
        return 1
    fi
}


# Function to check if the Podman machine is currently running.
# macOS only — on Linux, Podman runs natively without a VM.
is_podman_machine_running() {
    if podman machine list --format "{{.Running}}" 2>/dev/null | grep -q "true"; then
        log_success "Podman machine is running."
        return 0
    else
        log_info "Podman machine is not running."
        return 1
    fi
}


# Function to install Podman for the current platform.
# On macOS, also initializes and starts the required podman machine VM.
# On Linux (debian/fedora/arch), Podman runs natively — no VM step needed.
install_podman() {
    local os
    os="$(detect_os)"

    if ! is_podman_installed; then
        case "${os}" in
            macos)
                log_step "Installing Podman via Homebrew..."
                install_pkg podman
                log_success "Podman installation completed."
                ;;
            debian)
                log_step "Installing Podman via apt..."
                install_pkg podman
                log_success "Podman installation completed."
                ;;
            fedora)
                log_step "Installing Podman via dnf..."
                install_pkg podman
                log_success "Podman installation completed."
                ;;
            arch)
                log_step "Installing Podman via pacman..."
                install_pkg podman
                log_success "Podman installation completed."
                ;;
            *)
                log_error "install_podman: unsupported OS '${os}'"
                return 1
                ;;
        esac
    fi

    # podman machine init/start is macOS-only.
    # On Linux, Podman communicates with the container runtime directly.
    if [[ "${os}" == "macos" ]]; then
        if ! is_podman_machine_initialized; then
            log_step "Initializing Podman machine..."
            podman machine init
            log_success "Podman machine initialization completed."
        fi

        if ! is_podman_machine_running; then
            log_step "Starting Podman machine..."
            podman machine start
            log_success "Podman machine started."
        fi
    fi
}


# Function to print the installed Podman version.
print_podman_version() {
    if is_podman_installed; then
        log_info "Podman version:"
        podman --version
    else
        log_warn "Podman is not installed yet."
    fi
}


export -f is_podman_installed
export -f is_podman_machine_initialized
export -f is_podman_machine_running
export -f install_podman
export -f print_podman_version


# Run install and version check when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_podman
    print_podman_version
fi
