#!/bin/bash

# snap.sh — Snap package manager helper for Linux.
#
# Provides:
#   is_snap_installed      — returns 0 if snap is found on PATH, 1 otherwise
#   ensure_snap_installed  — installs snapd via the distro package manager if absent
#   install_snap_pkg       — installs a snap package from the stable channel
#   install_snap_classic   — installs a snap package with the --classic confinement flag
#   remove_snap_pkg        — removes a snap package
#   list_snap_pkgs         — lists all installed snap packages

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"

# Linux-only guard
if is_macos; then
    log_error "snap.sh is Linux-only. Snap is not available on macOS. Aborting."
    exit 1
fi


# Function to check if snap is installed.
# Parameters: None
# Returns: 0 if snap is installed, 1 otherwise
is_snap_installed() {
    if command -v snap &> /dev/null; then
        return 0
    else
        return 1
    fi
}


# Function to install snapd using the distro-appropriate package manager if snap
# is not already present. Enables and starts the snapd systemd service after
# installation. On Fedora, also creates the /snap compatibility symlink.
# Parameters: None
# Returns: None
ensure_snap_installed() {
    if is_snap_installed; then
        log_info "snap is already installed. Skipping snapd installation."
        return 0
    fi

    log_step "Installing snapd"

    case "$(detect_os)" in
        debian)
            log_info "Detected Debian-based system. Installing snapd via apt-get..."
            sudo apt-get install -y snapd
            sudo systemctl enable --now snapd
            ;;
        fedora)
            log_info "Detected Fedora-based system. Installing snapd via dnf..."
            sudo dnf install -y snapd
            sudo systemctl enable --now snapd
            sudo ln -sf /var/lib/snapd/snap /snap
            ;;
        arch)
            log_info "Detected Arch-based system. Installing snapd via pacman..."
            sudo pacman -S --noconfirm snapd
            sudo systemctl enable --now snapd
            ;;
        *)
            log_error "ensure_snap_installed: unsupported Linux distribution '$(detect_os)'. Install snapd manually."
            return 1
            ;;
    esac

    log_success "snapd installed and enabled successfully."
}


# Function to install a snap package from the stable channel.
# Parameters:
#   $1 — the snap package name
# Returns: None
install_snap_pkg() {
    local name="$1"

    if [[ -z "$name" ]]; then
        log_error "install_snap_pkg: package name is required."
        return 1
    fi

    log_info "Installing snap package (stable): $name"
    sudo snap install "$name"
    log_success "Snap package installed: $name"
}


# Function to install a snap package with --classic confinement.
# Required for applications such as IDEs (e.g. code, cursor) that need
# broader system access than the default strict confinement allows.
# Parameters:
#   $1 — the snap package name
# Returns: None
install_snap_classic() {
    local name="$1"

    if [[ -z "$name" ]]; then
        log_error "install_snap_classic: package name is required."
        return 1
    fi

    log_info "Installing snap package (classic confinement): $name"
    sudo snap install --classic "$name"
    log_success "Snap package installed with classic confinement: $name"
}


# Function to remove an installed snap package.
# Parameters:
#   $1 — the snap package name
# Returns: None
remove_snap_pkg() {
    local name="$1"

    if [[ -z "$name" ]]; then
        log_error "remove_snap_pkg: package name is required."
        return 1
    fi

    log_info "Removing snap package: $name"
    sudo snap remove "$name"
    log_success "Snap package removed: $name"
}


# Function to list all installed snap packages.
# Parameters: None
# Returns: None
list_snap_pkgs() {
    snap list
}


export -f is_snap_installed
export -f ensure_snap_installed
export -f install_snap_pkg
export -f install_snap_classic
export -f remove_snap_pkg
export -f list_snap_pkgs


# When executed directly, print the snap version if installed, or print
# installation instructions if snapd is not present.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if is_snap_installed; then
        log_info "snap is installed."
        snap --version
    else
        log_warn "snap is not installed."
        log_info "To install snapd, run one of the following commands for your distribution:"
        log_info "  Debian/Ubuntu : sudo apt-get install -y snapd && sudo systemctl enable --now snapd"
        log_info "  Fedora        : sudo dnf install -y snapd && sudo systemctl enable --now snapd && sudo ln -sf /var/lib/snapd/snap /snap"
        log_info "  Arch          : sudo pacman -S --noconfirm snapd && sudo systemctl enable --now snapd"
        log_info "Or source this script and call ensure_snap_installed."
    fi
fi
