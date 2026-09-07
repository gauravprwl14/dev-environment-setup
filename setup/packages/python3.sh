#!/bin/bash

# packages/python3.sh — Cross-platform Python 3 installation script.
# macOS  : Homebrew (brew install python3)
# Debian : apt-get install python3 python3-pip python3-venv
# Fedora : dnf install python3 python3-pip
# Arch   : pacman -S python python-pip

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"


# is_python3_installed
# Returns 0 if the python3 binary is available on PATH, 1 otherwise.
# Parameters: None
# Returns: 0 if Python 3 is installed, 1 otherwise
is_python3_installed() {
    if command -v python3 &> /dev/null; then
        log_info "Python 3 is installed."
        return 0
    else
        log_info "Python 3 is not installed."
        return 1
    fi
}


# install_python3
# Installs Python 3 (plus pip and venv where the package manager splits them
# into separate packages) using the platform-appropriate package manager.
# Parameters: None
# Returns: 0 on success, 1 on failure
install_python3() {
    if is_python3_installed; then
        log_info "Python 3 is already installed."
        print_python3_version
        return 0
    fi

    log_step "Installing Python 3..."

    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            install_pkg python3 || { log_error "install_python3: Homebrew install failed."; return 1; }
            ;;
        debian)
            install_pkg python3 || { log_error "install_python3: apt install failed."; return 1; }
            install_pkg python3-pip || log_warn "install_python3: python3-pip install failed; continuing."
            install_pkg python3-venv || log_warn "install_python3: python3-venv install failed; continuing."
            ;;
        fedora)
            install_pkg python3 || { log_error "install_python3: dnf install failed."; return 1; }
            install_pkg python3-pip || log_warn "install_python3: python3-pip install failed; continuing."
            ;;
        arch)
            install_pkg python || { log_error "install_python3: pacman install failed."; return 1; }
            install_pkg python-pip || log_warn "install_python3: python-pip install failed; continuing."
            ;;
        *)
            log_error "Python 3: unsupported OS '${os}'."
            return 1
            ;;
    esac

    if is_python3_installed; then
        log_success "Python 3 installation completed."
        print_python3_version
    else
        log_error "Python 3 installation failed."
        return 1
    fi
}


# print_python3_version
# Prints the currently installed Python 3 version.
# Parameters: None
# Returns: None
print_python3_version() {
    log_info "Python 3 version: $(python3 --version)"
}


export -f is_python3_installed
export -f install_python3
export -f print_python3_version


# Call the install function if this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_python3
fi
