#!/bin/bash

# packages/yt-dlp.sh — Cross-platform yt-dlp installation script.
# yt-dlp is a feature-rich, actively maintained fork of youtube-dl for
# downloading video/audio from YouTube and other sites.
# macOS  : Homebrew (brew install yt-dlp)
# Debian : apt-get install yt-dlp
# Fedora : dnf install yt-dlp
# Arch   : pacman -S yt-dlp

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"


# is_yt_dlp_installed
# Returns 0 if the yt-dlp binary is available on PATH, 1 otherwise.
# Parameters: None
# Returns: 0 if yt-dlp is installed, 1 otherwise
is_yt_dlp_installed() {
    if command -v yt-dlp &> /dev/null; then
        log_info "yt-dlp is installed."
        return 0
    else
        log_info "yt-dlp is not installed."
        return 1
    fi
}


# install_yt_dlp
# Installs yt-dlp using the platform-appropriate package manager.
# Parameters: None
# Returns: 0 on success, 1 on failure
install_yt_dlp() {
    if is_yt_dlp_installed; then
        log_info "yt-dlp is already installed."
        print_yt_dlp_version
        return 0
    fi

    log_step "Installing yt-dlp..."

    local os
    os="$(detect_os)"

    case "${os}" in
        macos|debian|fedora|arch)
            install_pkg yt-dlp || { log_error "install_yt_dlp: package manager install failed."; return 1; }
            ;;
        *)
            log_error "yt-dlp: unsupported OS '${os}'."
            return 1
            ;;
    esac

    if is_yt_dlp_installed; then
        log_success "yt-dlp installation completed."
        print_yt_dlp_version
    else
        log_error "yt-dlp installation failed."
        return 1
    fi
}


# print_yt_dlp_version
# Prints the currently installed yt-dlp version.
# Parameters: None
# Returns: None
print_yt_dlp_version() {
    log_info "yt-dlp version: $(yt-dlp --version)"
}


export -f is_yt_dlp_installed
export -f install_yt_dlp
export -f print_yt_dlp_version


# Call the install function if this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_yt_dlp
fi
