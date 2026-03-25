#!/bin/bash

# packages/apps/cursor.sh — Cross-platform Cursor IDE installation script.
# Supports macOS (Homebrew Cask), Debian-based and Fedora-based Linux
# (official AppImage or Snap), and Arch Linux (AUR helper).
# Cursor is an AI-powered code editor built on top of VS Code.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"


# is_cursor_installed
# Returns 0 if Cursor is detected on the current system, 1 otherwise.
# Detection strategy:
#   macOS  : brew list --cask cursor
#   Linux  : command -v cursor, or presence of /opt/cursor, or /snap/bin/cursor
# Parameters: None
# Returns: 0 if Cursor is installed, 1 otherwise
is_cursor_installed() {
    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            if brew list --cask cursor &> /dev/null; then
                log_info "Cursor is installed (Homebrew Cask)."
                return 0
            fi
            ;;
        debian|fedora|arch|linux)
            if command -v cursor &> /dev/null; then
                log_info "Cursor is installed (found on PATH)."
                return 0
            fi
            if [[ -d /opt/cursor ]]; then
                log_info "Cursor is installed (found at /opt/cursor)."
                return 0
            fi
            if [[ -f /snap/bin/cursor ]]; then
                log_info "Cursor is installed (found at /snap/bin/cursor)."
                return 0
            fi
            ;;
    esac

    log_info "Cursor is not installed."
    return 1
}


# _install_cursor_appimage
# Downloads the official Cursor AppImage, makes it executable, places it in
# /opt/cursor/, and creates a symlink at /usr/local/bin/cursor.
# Used as the primary installation path on Debian-based and Fedora-based Linux.
# Parameters: None
# Returns: 0 on success, 1 on failure
_install_cursor_appimage() {
    local arch
    arch="$(detect_arch)"

    local appimage_url
    # Cursor publishes architecture-specific AppImages; default to x86_64.
    if [[ "${arch}" == "arm64" ]]; then
        appimage_url="https://downloader.cursor.sh/linux/appImage/arm64"
    else
        appimage_url="https://downloader.cursor.sh/linux/appImage/x64"
    fi

    log_info "Downloading Cursor AppImage from ${appimage_url} ..."

    sudo mkdir -p /opt/cursor

    if ! sudo curl -fsSL "${appimage_url}" -o /opt/cursor/cursor.AppImage; then
        log_error "Failed to download the Cursor AppImage."
        return 1
    fi

    sudo chmod +x /opt/cursor/cursor.AppImage

    log_info "Creating symlink /usr/local/bin/cursor -> /opt/cursor/cursor.AppImage"
    sudo ln -sf /opt/cursor/cursor.AppImage /usr/local/bin/cursor

    log_success "Cursor AppImage installed to /opt/cursor and linked to /usr/local/bin/cursor."
}


# _install_cursor_snap
# Installs Cursor via Snap with classic confinement.
# Used as a fallback on Debian-based and Fedora-based Linux when the AppImage
# download fails.
# Parameters: None
# Returns: 0 on success, 1 on failure
_install_cursor_snap() {
    log_info "Attempting to install Cursor via Snap (classic confinement)..."

    if ! command -v snap &> /dev/null; then
        log_warn "snap is not available. Skipping Snap installation path."
        return 1
    fi

    if sudo snap install cursor --classic; then
        log_success "Cursor installed via Snap."
        return 0
    else
        log_error "Snap installation of Cursor failed."
        return 1
    fi
}


# install_cursor
# Installs the Cursor IDE using the appropriate method for the current OS:
#   macOS          : Homebrew Cask (brew install --cask cursor)
#   Debian/Fedora  : Official AppImage downloaded to /opt/cursor with a
#                    /usr/local/bin/cursor symlink; falls back to Snap if the
#                    AppImage download fails
#   Arch           : AUR helper (yay/paru) via install_cask
# Parameters: None
# Returns: None
install_cursor() {
    if is_cursor_installed; then
        log_success "Cursor is already installed. Skipping."
        print_cursor_version
        return 0
    fi

    local os
    os="$(detect_os)"

    log_step "Installing Cursor IDE (OS: ${os})"

    case "${os}" in
        macos)
            log_info "Installing Cursor via Homebrew Cask..."
            install_cask cursor
            ;;

        debian|fedora)
            # Preferred: official AppImage. Fallback: Snap.
            if ! _install_cursor_appimage; then
                log_warn "AppImage installation failed. Falling back to Snap..."
                if ! _install_cursor_snap; then
                    log_error "All Cursor installation methods failed on ${os}."
                    return 1
                fi
            fi
            ;;

        arch)
            log_info "Installing Cursor via AUR helper..."
            install_cask cursor
            ;;

        *)
            log_error "install_cursor: unsupported OS '${os}'"
            return 1
            ;;
    esac

    if is_cursor_installed; then
        log_success "Cursor installation completed."
        print_cursor_version
    else
        log_error "Cursor installation failed."
        return 1
    fi
}


# print_cursor_version
# Prints the installed Cursor version if the cursor binary is available on PATH.
# Parameters: None
# Returns: None
print_cursor_version() {
    if command -v cursor &> /dev/null; then
        log_info "Cursor version: $(cursor --version 2>&1)"
    else
        log_warn "cursor binary not found on PATH; cannot print version."
    fi
}


export -f is_cursor_installed
export -f _install_cursor_appimage
export -f _install_cursor_snap
export -f install_cursor
export -f print_cursor_version


# Call install_cursor when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_cursor
fi
