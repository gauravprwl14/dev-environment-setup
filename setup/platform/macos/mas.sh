#!/bin/bash

# platform/macos/mas.sh — Install and manage mas (Mac App Store CLI).
#
# mas is installed via Homebrew and provides a command-line interface for
# the Mac App Store, enabling scripted installation of App Store applications
# by their numeric App Store ID.
#
# Public functions:
#   is_mas_installed          — returns 0 if mas is present on PATH
#   install_mas               — installs mas via Homebrew if not already present
#   mas_install <app_id>      — installs a Mac App Store app by numeric ID
#
# Usage (source from another script):
#   source "$(dirname "${BASH_SOURCE[0]}")/mas.sh"

_MAS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${_MAS_DIR}/../../lib/logger.sh"
source "${_MAS_DIR}/../../lib/detect_os.sh"
source "${_MAS_DIR}/../../platform/macos/homebrew.sh"


# Function to check if mas (Mac App Store CLI) is installed.
# Parameters: None
# Returns: 0 if mas is installed, 1 otherwise
is_mas_installed() {
    if command -v mas &> /dev/null; then
        return 0
    else
        return 1
    fi
}


# Function to install mas (Mac App Store CLI) via Homebrew.
# Ensures Homebrew is present first, then installs mas if not already installed.
# Parameters: None
# Returns: None
install_mas() {
    if ! is_macos; then
        log_warn "mas is only available on macOS. Skipping."
        return 0
    fi

    log_step "Setting up mas (Mac App Store CLI)"

    if is_homebrew_installed; then
        log_info "Homebrew is installed."
    else
        log_info "Homebrew is not installed. Installing Homebrew..."
        install_homebrew
    fi

    if is_mas_installed; then
        log_success "mas is already installed."
    else
        log_info "mas not found, installing..."
        brew install mas
        log_success "mas installation complete."
    fi
}


# Function to install a Mac App Store application by its numeric App Store ID.
# Requires mas to be installed and the user to be signed in to the App Store.
# Parameters:
#   $1 — App Store numeric application ID (required)
# Returns: 0 on success, 1 if app_id is missing or not on macOS
mas_install() {
    local app_id="${1:-}"

    if ! is_macos; then
        log_warn "mas_install is only supported on macOS. Skipping."
        return 1
    fi

    if [[ -z "${app_id}" ]]; then
        log_error "mas_install requires an App Store app ID as the first argument."
        return 1
    fi

    if ! is_mas_installed; then
        log_info "mas is not installed. Installing mas first..."
        install_mas
    fi

    if mas list | grep -q "^${app_id}"; then
        log_success "App ${app_id} is already installed."
    else
        log_info "Installing App Store app with ID: ${app_id}..."
        mas install "${app_id}"
        log_success "App ${app_id} installation complete."
    fi
}


# Export functions for use in sourced scripts and subshells.
export -f is_mas_installed
export -f install_mas
export -f mas_install


# Run install_mas directly when this script is executed (not sourced).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_mas
fi
