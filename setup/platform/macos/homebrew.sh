#!/bin/bash

# homebrew.sh — Install and configure Homebrew on macOS.
#
# Provides:
#   is_homebrew_installed   — returns 0 if Homebrew is found on PATH, 1 otherwise
#   install_homebrew        — installs Homebrew if absent, or updates it if present;
#                             registers the Homebrew bin directory in the shell rc file

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../utils/update_shell_rc.sh"

# macOS-only guard
if ! is_macos; then
    log_error "homebrew.sh is macOS-only. Detected OS: $(detect_os). Aborting."
    exit 1
fi


# Function to check if Homebrew is installed.
# Parameters: None
# Returns: 0 if Homebrew is installed, 1 otherwise
is_homebrew_installed() {
    if command -v brew &> /dev/null; then
        return 0
    else
        return 1
    fi
}


# Function to install Homebrew (or update it if already present) and register
# its bin directory in the shell rc file.
# Parameters: None
# Returns: None
install_homebrew() {
    log_step "Homebrew"

    if ! is_homebrew_installed; then
        log_info "Homebrew is not installed. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        log_success "Homebrew installed successfully."
    else
        log_info "Homebrew is already installed. Updating Homebrew..."
        brew update
        log_success "Homebrew updated successfully."
    fi

    # Determine the correct Homebrew bin path for the current architecture.
    # Apple Silicon Macs use /opt/homebrew/bin; Intel Macs use /usr/local/bin.
    local homebrew_bin
    if [[ "$(detect_arch)" == "arm64" ]]; then
        homebrew_bin="/opt/homebrew/bin"
    else
        homebrew_bin="/usr/local/bin"
    fi

    log_info "Registering Homebrew PATH: $homebrew_bin"

    # Persist the Homebrew bin directory in the shell rc file.
    HOMEBREW_VARIABLE_NAME="HOMEBREW"
    add_to_shell_rc "$HOMEBREW_VARIABLE_NAME" "$homebrew_bin"
}


export -f is_homebrew_installed
export -f install_homebrew


# Call the install function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_homebrew
fi
