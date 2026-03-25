#!/bin/bash

# packages/cocoapods.sh — Cross-platform CocoaPods installation script.
# CocoaPods is macOS-only. On Linux this script logs a warning and exits cleanly.
# Preferred installation method on macOS: brew install cocoapods
# Falls back to: sudo gem install cocoapods

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"


# is_cocoapods_installed
# Returns 0 if the pod binary is available on PATH, 1 otherwise.
# Parameters: None
# Returns: 0 if CocoaPods is installed, 1 otherwise
is_cocoapods_installed() {
    if command -v pod &> /dev/null; then
        log_info "CocoaPods is installed."
        return 0
    else
        log_info "CocoaPods is not installed."
        return 1
    fi
}


# install_cocoapods
# Installs CocoaPods on macOS using Homebrew (preferred method).
# Falls back to: sudo gem install cocoapods when Homebrew is unavailable.
# On Linux, logs a warning and returns immediately without error.
# Parameters: None
# Returns: 0 on success or skip, 1 on failure
install_cocoapods() {
    if is_linux; then
        log_warn "CocoaPods is macOS-only. Skipping installation on Linux."
        return 0
    fi

    if is_cocoapods_installed; then
        log_info "CocoaPods is already installed."
        print_cocoapods_version
        return 0
    fi

    log_step "Installing CocoaPods..."

    # Preferred method: Homebrew
    if command -v brew &> /dev/null; then
        log_info "Installing CocoaPods via Homebrew..."
        install_pkg cocoapods
    else
        log_warn "Homebrew not found — falling back to gem install."
        log_info "Installing CocoaPods via RubyGems..."
        sudo gem install cocoapods
    fi

    if is_cocoapods_installed; then
        log_success "CocoaPods installation completed."
        print_cocoapods_version
    else
        log_error "CocoaPods installation failed."
        return 1
    fi
}


# print_cocoapods_version
# Prints the currently installed CocoaPods version.
# Parameters: None
# Returns: None
print_cocoapods_version() {
    log_info "CocoaPods version: $(pod --version)"
}


export -f is_cocoapods_installed
export -f install_cocoapods
export -f print_cocoapods_version


# Call the install function if this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_cocoapods
fi
