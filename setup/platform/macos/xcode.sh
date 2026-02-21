#!/bin/bash

# xcode.sh — Install Xcode Command Line Tools on macOS.
#
# Provides:
#   is_xcode_installed   — returns 0 if Xcode.app is present, 1 otherwise
#   install_xcode        — installs Xcode CLI tools via xcode-select --install

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"

# macOS-only guard
if ! is_macos; then
    log_error "xcode.sh is macOS-only. Detected OS: $(detect_os). Aborting."
    exit 1
fi


# Function to check if Xcode is installed.
# Parameters: None
# Returns: 0 if Xcode.app is present, 1 otherwise
is_xcode_installed() {
    if [ -d "/Applications/Xcode.app" ]; then
        log_info "Xcode is installed."
        return 0
    else
        log_warn "Xcode is not installed."
        return 1
    fi
}


# Function to install Xcode Command Line Tools via xcode-select.
# Parameters: None
# Returns: None
install_xcode() {
    log_step "Xcode Command Line Tools"

    # Check if the Command Line Tools are already installed
    if xcode-select --print-path &> /dev/null; then
        log_success "Xcode Command Line Tools are already installed."
        return 0
    fi

    log_info "Xcode Command Line Tools not found, installing..."

    # Trigger the installation of Command Line Tools
    xcode-select --install

    # Wait until the Command Line Tools are installed
    until xcode-select --print-path &> /dev/null; do
        log_info "Waiting for Xcode Command Line Tools installation to complete..."
        sleep 5
    done

    log_success "Xcode Command Line Tools installed successfully."
}


export -f is_xcode_installed
export -f install_xcode


# Call the install function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_xcode
fi
