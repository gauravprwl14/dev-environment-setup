#!/bin/bash

# apt.sh — Ubuntu/Debian bootstrap script for the cross-platform dev environment setup tool.
#
# Provides:
#   bootstrap_apt         — run once to prepare a fresh Ubuntu/Debian system with essentials,
#                           flatpak (with Flathub remote), and snapd
#   is_apt_bootstrapped   — returns 0 if curl, git, and build-essential are available, 1 otherwise
#   add_apt_repo          — adds an apt repository line to /etc/apt/sources.list.d/ and updates
#   add_apt_key           — downloads a GPG key and saves it to a given keyring path

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"

# Debian-only guard
if [[ "$(detect_os)" != "debian" ]]; then
    log_error "apt.sh is Debian/Ubuntu-only. Detected OS: $(detect_os). Aborting."
    exit 1
fi


# bootstrap_apt
# Run once to prepare a fresh Ubuntu/Debian system.
# Installs essential packages, flatpak with the Flathub remote, and snapd.
# Parameters: None
# Returns: None
bootstrap_apt() {
    log_step "APT bootstrap"

    log_info "Updating apt package index..."
    sudo apt-get update
    log_success "apt package index updated."

    log_info "Installing essential packages..."
    sudo apt-get install -y \
        curl \
        git \
        build-essential \
        software-properties-common \
        ca-certificates \
        gnupg \
        lsb-release \
        wget
    log_success "Essential packages installed."

    log_info "Installing flatpak..."
    sudo apt-get install -y flatpak
    log_success "flatpak installed."

    log_info "Adding Flathub remote..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    log_success "Flathub remote added."

    if command -v snapd &> /dev/null; then
        log_info "snapd is already installed. Skipping."
    else
        log_info "Installing snapd..."
        sudo apt-get install -y snapd
        log_success "snapd installed."
    fi

    log_success "APT bootstrap complete."
}


# is_apt_bootstrapped
# Checks that curl, git, and build-essential are available.
# build-essential installs gcc, so its presence is used as the proxy check.
# Parameters: None
# Returns: 0 if all three are present, 1 otherwise
is_apt_bootstrapped() {
    if command -v curl &> /dev/null && \
       command -v git &> /dev/null && \
       command -v gcc &> /dev/null; then
        return 0
    else
        return 1
    fi
}


# add_apt_repo <repo_line>
# Adds an apt repository line to /etc/apt/sources.list.d/ and refreshes the index.
# Parameters:
#   $1 — the full deb source line (e.g. "deb [arch=amd64] https://example.com/repo focal main")
# Returns: None
add_apt_repo() {
    local repo_line="$1"

    if [[ -z "${repo_line}" ]]; then
        log_error "add_apt_repo: no repository line provided."
        return 1
    fi

    # Derive a safe filename from the repo line by stripping non-alphanumeric chars.
    local repo_file
    repo_file="/etc/apt/sources.list.d/$(echo "${repo_line}" | tr -cs '[:alnum:]' '-' | sed 's/^-//;s/-$//' | cut -c1-64).list"

    log_info "Adding apt repository: ${repo_line}"
    echo "${repo_line}" | sudo tee "${repo_file}" > /dev/null
    log_success "Repository written to ${repo_file}."

    log_info "Updating apt package index after adding repository..."
    sudo apt-get update
    log_success "apt package index updated."
}


# add_apt_key <url> <keyring_path>
# Downloads a GPG key from the given URL and saves it (dearmored) to the given keyring path.
# Parameters:
#   $1 — URL of the GPG key to download
#   $2 — destination path for the dearmored keyring (e.g. /usr/share/keyrings/example.gpg)
# Returns: None
add_apt_key() {
    local url="$1"
    local keyring_path="$2"

    if [[ -z "${url}" ]]; then
        log_error "add_apt_key: no key URL provided."
        return 1
    fi

    if [[ -z "${keyring_path}" ]]; then
        log_error "add_apt_key: no keyring path provided."
        return 1
    fi

    log_info "Downloading and installing GPG key from ${url} to ${keyring_path}..."
    curl -fsSL "${url}" | sudo gpg --dearmor -o "${keyring_path}"
    log_success "GPG key saved to ${keyring_path}."
}


export -f bootstrap_apt
export -f is_apt_bootstrapped
export -f add_apt_repo
export -f add_apt_key


# Call bootstrap_apt if this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bootstrap_apt
fi
