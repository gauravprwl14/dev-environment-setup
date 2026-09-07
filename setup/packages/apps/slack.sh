#!/bin/bash

# packages/apps/slack.sh — Cross-platform Slack installation script.
#
# Slack is a team messaging and collaboration app.
#
# Platform support:
#   macOS          : Homebrew Cask (slack)
#   Debian/Fedora  : Flatpak (flathub com.slack.Slack)
#   Arch           : AUR helper via install_cask (yay/paru) with flatpak fallback

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"


# Function to check if Slack is installed.
# Detection strategy varies by platform:
#   macOS          : brew list --cask slack
#   Linux (all)    : command -v slack OR flatpak list check
# Parameters: None
# Returns: 0 if Slack is installed, 1 otherwise
is_slack_installed() {
    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            if brew list --cask slack &> /dev/null; then
                log_info "Slack is installed (Homebrew Cask)."
                return 0
            else
                log_info "Slack is not installed."
                return 1
            fi
            ;;
        debian|fedora|arch|linux)
            if command -v slack &> /dev/null; then
                log_info "Slack is installed (command found on PATH)."
                return 0
            fi
            if command -v flatpak &> /dev/null && flatpak list --app | grep -q "com.slack.Slack"; then
                log_info "Slack is installed (Flatpak)."
                return 0
            fi
            log_info "Slack is not installed."
            return 1
            ;;
        *)
            log_warn "is_slack_installed: unsupported OS '${os}' — assuming not installed."
            return 1
            ;;
    esac
}


# Function to install Slack.
# Installation strategy varies by platform:
#   macOS          : brew install --cask slack
#   Debian/Fedora  : flatpak install -y flathub com.slack.Slack
#   Arch           : install_cask slack (AUR via yay/paru, flatpak fallback)
# Parameters: None
# Returns: 0 on success, 1 on unsupported OS or install failure
install_slack() {
    local os
    os="$(detect_os)"

    if is_slack_installed; then
        log_success "Slack is already installed. Skipping."
        return 0
    fi

    log_step "Installing Slack..."

    case "${os}" in
        macos)
            install_cask slack || { log_error "install_slack: Homebrew Cask install failed."; return 1; }
            ;;
        debian|fedora)
            flatpak install -y flathub com.slack.Slack || { log_error "install_slack: flatpak install failed."; return 1; }
            ;;
        arch)
            install_cask slack || { log_error "install_slack: install failed (AUR/flatpak)."; return 1; }
            ;;
        *)
            log_error "install_slack: unsupported OS '${os}'."
            return 1
            ;;
    esac

    if is_slack_installed; then
        log_success "Slack installation completed."
    else
        log_error "Slack installation failed."
        return 1
    fi
}


# Export functions so they are available when this script is sourced.
export -f is_slack_installed
export -f install_slack


# Run install_slack when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_slack
fi
