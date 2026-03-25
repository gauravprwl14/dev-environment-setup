#!/bin/bash

# packages/flutter.sh — Cross-platform Flutter SDK installer.
#
# Supported platforms:
#   macOS   : Homebrew Cask (brew install --cask flutter)
#   Debian  : Snap classic  (sudo snap install flutter --classic)
#   Fedora  : Snap classic  (sudo snap install flutter --classic)
#   Arch    : AUR via install_pkg (flutter package from AUR)
#
# Usage (standalone):
#   bash setup/packages/flutter.sh
#
# Usage (sourced):
#   source setup/packages/flutter.sh
#   install_flutter

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/update_shell_rc.sh"


# ---------------------------------------------------------------------------
# is_flutter_installed
# Returns 0 if the flutter binary is available on PATH, 1 otherwise.
# ---------------------------------------------------------------------------
is_flutter_installed() {
    if command -v flutter &> /dev/null; then
        log_success "Flutter is already installed."
        return 0
    else
        log_info "Flutter is not installed."
        return 1
    fi
}


# ---------------------------------------------------------------------------
# install_flutter
# Installs Flutter using the appropriate method for the current OS, then
# registers FLUTTER_HOME in the shell rc file and runs flutter doctor.
# ---------------------------------------------------------------------------
install_flutter() {
    if is_flutter_installed; then
        return 0
    fi

    local os
    os="$(detect_os)"

    log_step "Installing Flutter..."

    case "${os}" in
        macos)
            log_info "Installing Flutter via Homebrew Cask..."
            brew install --cask flutter
            ;;
        debian|fedora)
            log_info "Installing Flutter via Snap (classic confinement)..."
            sudo snap install flutter --classic
            ;;
        arch)
            log_info "Installing Flutter via AUR..."
            install_pkg flutter
            ;;
        *)
            log_error "Unsupported OS '${os}'. Cannot install Flutter automatically."
            return 1
            ;;
    esac

    # Determine the Flutter SDK home path for the current OS
    local flutter_home
    case "${os}" in
        macos)
            flutter_home="/opt/homebrew/Caskroom/flutter/latest/flutter/bin"
            ;;
        debian|fedora)
            # Snap exposes the flutter binary through $SNAP; the canonical SDK
            # location for snap installs is under /snap/flutter/current.
            flutter_home="/snap/flutter/current/flutter/bin"
            ;;
        arch)
            flutter_home="/opt/flutter/bin"
            ;;
    esac

    log_info "Registering FLUTTER_HOME in shell rc..."
    add_to_shell_rc "FLUTTER_HOME" "${flutter_home}"

    log_step "Running flutter doctor..."
    flutter doctor

    log_success "Flutter installation completed."
}


# ---------------------------------------------------------------------------
# print_flutter_version
# Prints the installed Flutter version.
# ---------------------------------------------------------------------------
print_flutter_version() {
    log_info "Flutter version:"
    flutter --version
}


# ---------------------------------------------------------------------------
# Export all public functions
# ---------------------------------------------------------------------------
export -f is_flutter_installed
export -f install_flutter
export -f print_flutter_version


# ---------------------------------------------------------------------------
# BASH_SOURCE guard — run install when executed directly
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_flutter
    print_flutter_version
fi
