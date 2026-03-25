#!/bin/bash

# dnf.sh — Fedora/RHEL bootstrap script for the dev-environment-setup CLI.
#
# Provides:
#   bootstrap_dnf        — prepare a fresh Fedora/RHEL system with essentials,
#                          RPM Fusion repos, Flatpak, and Flathub
#   is_dnf_bootstrapped  — returns 0 if curl, git, and gcc are available
#   add_dnf_repo         — adds a .repo file via dnf config-manager
#   add_dnf_copr         — enables a COPR repository

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"

# Fedora/RHEL-only guard
if [[ "$(detect_os)" != "fedora" ]]; then
    log_error "dnf.sh is Fedora/RHEL-only. Detected OS: $(detect_os). Aborting."
    exit 1
fi


# Function to prepare a fresh Fedora/RHEL system.
# Installs essential build tools, enables RPM Fusion repos,
# installs Flatpak, and registers the Flathub remote.
# Parameters: None
# Returns: None
bootstrap_dnf() {
    log_step "DNF Bootstrap"

    # Refresh package metadata; dnf check-update exits 100 when updates are
    # available — that is expected and not an error.
    log_info "Refreshing DNF package metadata..."
    sudo dnf check-update || true
    log_success "DNF package metadata refreshed."

    # Install essential build tools and utilities
    log_info "Installing essential packages (curl git make gcc gcc-c++ kernel-devel wget ca-certificates gnupg2)..."
    sudo dnf install -y \
        curl \
        git \
        make \
        gcc \
        gcc-c++ \
        kernel-devel \
        wget \
        ca-certificates \
        gnupg2
    log_success "Essential packages installed."

    # Enable RPM Fusion free repository
    log_info "Enabling RPM Fusion free repository..."
    sudo dnf install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    log_success "RPM Fusion free repository enabled."

    # Enable RPM Fusion nonfree repository
    log_info "Enabling RPM Fusion nonfree repository..."
    sudo dnf install -y \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    log_success "RPM Fusion nonfree repository enabled."

    # Install Flatpak
    log_info "Installing Flatpak..."
    sudo dnf install -y flatpak
    log_success "Flatpak installed."

    # Add the Flathub remote
    log_info "Adding Flathub remote for Flatpak..."
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    log_success "Flathub remote added."

    log_success "DNF bootstrap complete."
}


# Function to check whether the system has been bootstrapped.
# Verifies that curl, git, and gcc are available on PATH.
# Parameters: None
# Returns: 0 if all three tools are present, 1 otherwise
is_dnf_bootstrapped() {
    for tool in curl git gcc; do
        if ! command -v "$tool" &> /dev/null; then
            log_warn "Bootstrap check failed: '$tool' not found."
            return 1
        fi
    done
    log_info "Bootstrap check passed: curl, git, and gcc are available."
    return 0
}


# Function to add a DNF repository from a .repo URL.
# Parameters:
#   $1  repo_url — URL of the .repo file to add
# Returns: None
add_dnf_repo() {
    local repo_url="$1"

    if [[ -z "${repo_url}" ]]; then
        log_error "add_dnf_repo: no repo URL provided."
        return 1
    fi

    log_info "Adding DNF repository: ${repo_url}"
    sudo dnf config-manager --add-repo "${repo_url}"
    log_success "DNF repository added: ${repo_url}"
}


# Function to enable a COPR repository.
# Parameters:
#   $1  copr_name — COPR project in the form <user>/<project>
# Returns: None
add_dnf_copr() {
    local copr_name="$1"

    if [[ -z "${copr_name}" ]]; then
        log_error "add_dnf_copr: no COPR name provided."
        return 1
    fi

    log_info "Enabling COPR repository: ${copr_name}"
    sudo dnf copr enable "${copr_name}" -y
    log_success "COPR repository enabled: ${copr_name}"
}


export -f bootstrap_dnf
export -f is_dnf_bootstrapped
export -f add_dnf_repo
export -f add_dnf_copr


# Call bootstrap_dnf if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bootstrap_dnf
fi
