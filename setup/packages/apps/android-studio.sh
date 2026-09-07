#!/bin/bash

# packages/apps/android-studio.sh — Cross-platform Android Studio installation script.
# macOS  : Homebrew Cask (brew install --cask android-studio)
# Debian : Flatpak (flathub com.google.AndroidStudio), falls back to snap --classic
# Fedora : Flatpak (flathub com.google.AndroidStudio), falls back to snap --classic
# Arch   : AUR via yay/paru (package name: android-studio)
#
# Note: this installs the Android Studio IDE only. It does not provision the
# Android SDK, platform-tools, or emulator system images — those are managed
# separately via `sdkmanager`/`avdmanager` once Android Studio (and its bundled
# command-line tools) are present.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"


# is_android_studio_installed
# Returns 0 if Android Studio is detected on the current platform, 1 otherwise.
# Parameters: None
# Returns: 0 if installed, 1 otherwise
is_android_studio_installed() {
    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            if [[ -d "/Applications/Android Studio.app" ]]; then
                log_info "Android Studio is installed."
                return 0
            fi
            ;;
        debian|fedora|arch)
            if command -v android-studio &> /dev/null || command -v studio.sh &> /dev/null; then
                log_info "Android Studio is installed."
                return 0
            fi
            ;;
    esac

    log_info "Android Studio is not installed."
    return 1
}


# install_android_studio
# Installs Android Studio using the platform-appropriate mechanism.
# Parameters: None
# Returns: 0 on success, 1 on failure
install_android_studio() {
    if is_android_studio_installed; then
        log_info "Android Studio is already installed."
        return 0
    fi

    log_step "Installing Android Studio..."

    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            install_cask android-studio
            ;;
        debian|fedora)
            if command -v flatpak &> /dev/null; then
                log_info "Installing Android Studio via Flatpak..."
                flatpak install -y flathub com.google.AndroidStudio
            else
                log_info "Flatpak not found — installing Android Studio via snap (classic confinement)..."
                sudo snap install android-studio --classic
            fi
            ;;
        arch)
            log_info "Installing Android Studio via AUR..."
            if command -v yay &> /dev/null; then
                yay -S --noconfirm android-studio
            elif command -v paru &> /dev/null; then
                paru -S --noconfirm android-studio
            else
                log_error "Android Studio: no AUR helper (yay/paru) found on Arch."
                return 1
            fi
            ;;
        *)
            log_error "Android Studio: unsupported OS '${os}'."
            return 1
            ;;
    esac

    if is_android_studio_installed; then
        log_success "Android Studio installation completed."
    else
        log_error "Android Studio installation failed."
        return 1
    fi
}


export -f is_android_studio_installed
export -f install_android_studio


# Call the install function if this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_android_studio
fi
