#!/bin/bash

# packages/fzf.sh — Cross-platform fzf installation script.
# fzf is available natively on every supported platform's package manager.
# macOS  : Homebrew (brew install fzf)
# Debian : apt-get install fzf
# Fedora : dnf install fzf
# Arch   : pacman -S fzf

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"


# is_fzf_installed
# Returns 0 if the fzf binary is available on PATH, 1 otherwise.
# Parameters: None
# Returns: 0 if fzf is installed, 1 otherwise
is_fzf_installed() {
    if command -v fzf &> /dev/null; then
        log_info "fzf is installed."
        return 0
    else
        log_info "fzf is not installed."
        return 1
    fi
}


# install_fzf
# Installs fzf using the platform-appropriate package manager.
# Parameters: None
# Returns: 0 on success, 1 on failure
install_fzf() {
    if is_fzf_installed; then
        log_info "fzf is already installed."
        print_fzf_version
        return 0
    fi

    log_step "Installing fzf..."

    local os
    os="$(detect_os)"

    case "${os}" in
        macos|debian|fedora|arch)
            install_pkg fzf
            ;;
        *)
            log_error "fzf: unsupported OS '${os}'."
            return 1
            ;;
    esac

    if is_fzf_installed; then
        log_success "fzf installation completed."
        print_fzf_version
    else
        log_error "fzf installation failed."
        return 1
    fi
}


# print_fzf_version
# Prints the currently installed fzf version.
# Parameters: None
# Returns: None
print_fzf_version() {
    log_info "fzf version: $(fzf --version)"
}


export -f is_fzf_installed
export -f install_fzf
export -f print_fzf_version


# Call the install function if this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_fzf
fi
