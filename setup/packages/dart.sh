#!/bin/bash

# packages/dart.sh — Cross-platform Dart SDK installer.
#
# Supported platforms:
#   macOS   : Homebrew         (brew install dart)
#   Debian  : Dart apt repo    (apt-get install dart)
#   Fedora  : tarball download (extracted to /opt/dart-sdk, added to PATH)
#   Arch    : AUR via install_pkg (dart package from AUR)
#
# Usage (standalone):
#   bash setup/packages/dart.sh
#
# Usage (sourced):
#   source setup/packages/dart.sh
#   install_dart

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/update_shell_rc.sh"


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

DART_DEBIAN_GPG_URL="https://dl-ssl.google.com/linux/linux_signing_key.pub"
DART_DEBIAN_LIST="/etc/apt/sources.list.d/dart_stable.list"
DART_FEDORA_SDK_URL="https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip"
DART_FEDORA_SDK_DIR="/opt/dart-sdk"


# ---------------------------------------------------------------------------
# is_dart_installed
# Returns 0 if the dart binary is available on PATH, 1 otherwise.
# ---------------------------------------------------------------------------
is_dart_installed() {
    if command -v dart &> /dev/null; then
        log_success "Dart is already installed."
        return 0
    else
        log_info "Dart is not installed."
        return 1
    fi
}


# ---------------------------------------------------------------------------
# install_dart
# Installs the Dart SDK using the appropriate method for the current OS, then
# registers the Dart binary directory in the shell rc file.
# ---------------------------------------------------------------------------
install_dart() {
    if is_dart_installed; then
        return 0
    fi

    local os
    os="$(detect_os)"

    log_step "Installing Dart SDK..."

    case "${os}" in
        macos)
            log_info "Installing Dart via Homebrew..."
            install_pkg dart
            ;;
        debian)
            log_info "Adding Dart apt repository..."
            if ! command -v curl &> /dev/null; then
                log_error "curl is required to add the Dart apt repository but was not found on PATH."
                return 1
            fi
            curl -fsSL "${DART_DEBIAN_GPG_URL}" \
                | sudo gpg --dearmor -o /usr/share/keyrings/dart-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/dart-archive-keyring.gpg] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main" \
                | sudo tee "${DART_DEBIAN_LIST}" > /dev/null
            sudo apt-get update
            log_info "Installing Dart via apt-get..."
            sudo apt-get install -y dart
            ;;
        fedora)
            log_info "Downloading Dart SDK tarball for Fedora..."
            if ! command -v curl &> /dev/null; then
                log_error "curl is required to download the Dart SDK but was not found on PATH."
                return 1
            fi
            if ! command -v unzip &> /dev/null; then
                log_error "unzip is required to extract the Dart SDK but was not found on PATH."
                return 1
            fi
            local tmp_zip
            tmp_zip="$(mktemp --suffix=.zip)"
            curl -fsSL "${DART_FEDORA_SDK_URL}" -o "${tmp_zip}"
            sudo mkdir -p "${DART_FEDORA_SDK_DIR}"
            sudo unzip -o "${tmp_zip}" -d /opt
            rm -f "${tmp_zip}"
            log_info "Registering Dart SDK PATH in shell rc..."
            add_path_to_shell_rc "${DART_FEDORA_SDK_DIR}/bin"
            log_success "Dart SDK installed to ${DART_FEDORA_SDK_DIR}."
            return 0
            ;;
        arch)
            log_info "Installing Dart via AUR..."
            install_pkg dart
            ;;
        *)
            log_error "Unsupported OS '${os}'. Cannot install Dart automatically."
            return 1
            ;;
    esac

    log_success "Dart installation completed."
}


# ---------------------------------------------------------------------------
# print_dart_version
# Prints the installed Dart SDK version.
# ---------------------------------------------------------------------------
print_dart_version() {
    log_info "Dart version:"
    dart --version
}


# ---------------------------------------------------------------------------
# Export all public functions
# ---------------------------------------------------------------------------
export -f is_dart_installed
export -f install_dart
export -f print_dart_version


# ---------------------------------------------------------------------------
# BASH_SOURCE guard — run install when executed directly
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_dart
    print_dart_version
fi
