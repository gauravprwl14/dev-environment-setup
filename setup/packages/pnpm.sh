#!/bin/bash

# packages/pnpm.sh — Cross-platform pnpm installation script.
# Preferred installation method on all platforms: npm install -g pnpm
# Falls back to the native package manager when npm is unavailable.

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"


# is_pnpm_installed
# Returns 0 if the pnpm binary is available on PATH, 1 otherwise.
# Parameters: None
# Returns: 0 if pnpm is installed, 1 otherwise
is_pnpm_installed() {
    if command -v pnpm &> /dev/null; then
        log_info "pnpm is installed."
        return 0
    else
        log_info "pnpm is not installed."
        return 1
    fi
}


# install_pnpm
# Installs pnpm globally using npm install -g pnpm on all platforms
# (preferred method). Falls back to the native package manager when npm is
# not available:
#   macOS               : brew install pnpm
#   debian/fedora/arch   : install_pkg pnpm
# Parameters: None
# Returns: 0 on success, 1 on failure
install_pnpm() {
    if is_pnpm_installed; then
        log_info "pnpm is already installed."
        print_pnpm_version
        return 0
    fi

    log_step "Installing pnpm..."

    # Preferred method: npm install -g pnpm (works everywhere Node/npm is installed)
    if command -v npm &> /dev/null; then
        log_info "Installing pnpm via npm..."
        npm install -g pnpm || { log_error "install_pnpm: npm global install failed."; return 1; }
    else
        log_warn "npm not found — falling back to native package manager."

        local os
        os="$(detect_os)"

        case "${os}" in
            macos|debian|fedora|arch)
                install_pkg pnpm || { log_error "install_pnpm: package manager install failed."; return 1; }
                ;;
            *)
                log_error "Cannot install pnpm: npm is not available and no fallback exists for OS '${os}'."
                return 1
                ;;
        esac
    fi

    if is_pnpm_installed; then
        log_success "pnpm installation completed."
        print_pnpm_version
    else
        log_error "pnpm installation failed."
        return 1
    fi
}


# print_pnpm_version
# Prints the currently installed pnpm version.
# Parameters: None
# Returns: None
print_pnpm_version() {
    log_info "pnpm version: $(pnpm --version)"
}


export -f is_pnpm_installed
export -f install_pnpm
export -f print_pnpm_version


# Call the install function if this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_pnpm
fi
