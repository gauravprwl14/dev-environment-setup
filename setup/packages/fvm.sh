#!/bin/bash

# packages/fvm.sh — Cross-platform FVM (Flutter Version Manager) installer.
#
# FVM is installed via the Dart pub.dev package registry on all platforms.
# This requires Dart to be installed and `dart` to be available on PATH.
#
# Supported platforms: macOS, Debian, Fedora, Arch (any platform with Dart)
#
# Usage (standalone):
#   bash setup/packages/fvm.sh
#
# Usage (sourced):
#   source setup/packages/fvm.sh
#   install_fvm

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/update_shell_rc.sh"


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

PUB_CACHE_BIN='$HOME/.pub-cache/bin'


# ---------------------------------------------------------------------------
# is_fvm_installed
# Returns 0 if the fvm binary is available on PATH, 1 otherwise.
# ---------------------------------------------------------------------------
is_fvm_installed() {
    if command -v fvm &> /dev/null; then
        log_success "FVM is already installed."
        return 0
    else
        log_info "FVM is not installed."
        return 1
    fi
}


# ---------------------------------------------------------------------------
# install_fvm
# Installs FVM via `dart pub global activate fvm` on all platforms, then
# ensures $HOME/.pub-cache/bin is registered in the shell rc file.
# ---------------------------------------------------------------------------
install_fvm() {
    if is_fvm_installed; then
        return 0
    fi

    log_step "Installing FVM (Flutter Version Manager)..."

    if ! command -v dart &> /dev/null; then
        log_error "Dart is required to install FVM but was not found on PATH."
        log_error "Please install Dart first: bash setup/packages/dart.sh"
        return 1
    fi

    log_info "Activating FVM via dart pub global..."
    dart pub global activate fvm

    if [ $? -ne 0 ]; then
        log_error "FVM activation via dart pub global failed."
        return 1
    fi

    log_info "Registering \$HOME/.pub-cache/bin in shell rc..."
    add_path_to_shell_rc "${PUB_CACHE_BIN}"

    log_success "FVM installation completed."
}


# ---------------------------------------------------------------------------
# print_fvm_version
# Prints the installed FVM version.
# ---------------------------------------------------------------------------
print_fvm_version() {
    log_info "FVM version:"
    fvm --version
}


# ---------------------------------------------------------------------------
# Export all public functions
# ---------------------------------------------------------------------------
export -f is_fvm_installed
export -f install_fvm
export -f print_fvm_version


# ---------------------------------------------------------------------------
# BASH_SOURCE guard — run install when executed directly
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_fvm
    print_fvm_version
fi
