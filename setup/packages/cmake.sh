#!/bin/bash

# packages/cmake.sh — Cross-platform CMake installation script.
# CMake is available natively on every supported platform's package manager.
# macOS  : Homebrew (brew install cmake)
# Debian : apt-get install cmake
# Fedora : dnf install cmake
# Arch   : pacman -S cmake

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"


# is_cmake_installed
# Returns 0 if the cmake binary is available on PATH, 1 otherwise.
# Parameters: None
# Returns: 0 if CMake is installed, 1 otherwise
is_cmake_installed() {
    if command -v cmake &> /dev/null; then
        log_info "CMake is installed."
        return 0
    else
        log_info "CMake is not installed."
        return 1
    fi
}


# install_cmake
# Installs CMake using the platform-appropriate package manager.
# Parameters: None
# Returns: 0 on success, 1 on failure
install_cmake() {
    if is_cmake_installed; then
        log_info "CMake is already installed."
        print_cmake_version
        return 0
    fi

    log_step "Installing CMake..."

    local os
    os="$(detect_os)"

    case "${os}" in
        macos|debian|fedora|arch)
            install_pkg cmake
            ;;
        *)
            log_error "CMake: unsupported OS '${os}'."
            return 1
            ;;
    esac

    if is_cmake_installed; then
        log_success "CMake installation completed."
        print_cmake_version
    else
        log_error "CMake installation failed."
        return 1
    fi
}


# print_cmake_version
# Prints the currently installed CMake version.
# Parameters: None
# Returns: None
print_cmake_version() {
    log_info "CMake version: $(cmake --version | head -1)"
}


export -f is_cmake_installed
export -f install_cmake
export -f print_cmake_version


# Call the install function if this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_cmake
fi
