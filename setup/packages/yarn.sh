#!/bin/bash

# packages/yarn.sh — Cross-platform Yarn installation script.
# Preferred installation method on all platforms: npm install -g yarn
# Falls back to the native package manager when npm is unavailable.

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"


# is_yarn_installed
# Returns 0 if the yarn binary is available on PATH, 1 otherwise.
# Parameters: None
# Returns: 0 if Yarn is installed, 1 otherwise
is_yarn_installed() {
    if command -v yarn &> /dev/null; then
        log_info "Yarn is installed."
        return 0
    else
        log_info "Yarn is not installed."
        return 1
    fi
}


# install_yarn
# Installs Yarn using npm install -g yarn on all platforms (preferred method).
# Falls back to the native package manager when npm is not available:
#   macOS  : brew install yarn
#   debian : enable the Yarn apt repository then apt-get install yarn
# Parameters: None
# Returns: None
install_yarn() {
    if is_yarn_installed; then
        log_info "Yarn is already installed."
        print_yarn_version
        return 0
    fi

    log_step "Installing Yarn..."

    # Preferred method: npm install -g yarn (works everywhere Node/npm is installed)
    if command -v npm &> /dev/null; then
        log_info "Installing Yarn via npm..."
        npm install -g yarn
    else
        log_warn "npm not found — falling back to native package manager."

        local os
        os="$(detect_os)"

        case "${os}" in
            macos)
                log_info "Installing Yarn via Homebrew..."
                install_pkg yarn
                ;;
            debian)
                log_info "Enabling Yarn apt repository and installing..."
                curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg \
                    | sudo gpg --dearmor -o /usr/share/keyrings/yarn-archive-keyring.gpg
                echo "deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] \
https://dl.yarnpkg.com/debian/ stable main" \
                    | sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y yarn
                ;;
            *)
                log_error "Cannot install Yarn: npm is not available and no fallback exists for OS '${os}'."
                return 1
                ;;
        esac
    fi

    if is_yarn_installed; then
        log_success "Yarn installation completed."
        print_yarn_version
    else
        log_error "Yarn installation failed."
        return 1
    fi
}


# print_yarn_version
# Prints the currently installed Yarn version.
# Parameters: None
# Returns: None
print_yarn_version() {
    log_info "Yarn version: $(yarn --version)"
}


export -f is_yarn_installed
export -f install_yarn
export -f print_yarn_version


# Call the install function if this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_yarn
fi
