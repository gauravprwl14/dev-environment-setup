#!/bin/bash

# packages/watchman.sh — Cross-platform Watchman installation script.
# macOS  : Homebrew (brew install watchman)
# Debian : Official binary release downloaded from GitHub releases
# Fedora : Native package manager (dnf install watchman)
# Arch   : AUR via native package manager (yay/paru install watchman)

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"


# is_watchman_installed
# Returns 0 if the watchman binary is available on PATH, 1 otherwise.
# Parameters: None
# Returns: 0 if Watchman is installed, 1 otherwise
is_watchman_installed() {
    if command -v watchman &> /dev/null; then
        log_info "Watchman is installed."
        return 0
    else
        log_info "Watchman is not installed."
        return 1
    fi
}


# _install_watchman_debian
# Downloads and installs the official Watchman binary release from GitHub for
# Debian-based systems (Ubuntu, Debian, Linux Mint).
# Determines the correct architecture, fetches the latest release asset, and
# installs the binary to /usr/local/bin.
# Parameters: None
# Returns: 0 on success, 1 on failure
_install_watchman_debian() {
    local arch os_tag tmp_dir zip_path bin_src

    arch="$(detect_arch)"

    case "${arch}" in
        x86_64)
            os_tag="linux-x86_64"
            ;;
        arm64)
            os_tag="linux-aarch64"
            ;;
        *)
            log_error "Watchman: unsupported architecture '${arch}' for binary installation."
            return 1
            ;;
    esac

    log_info "Resolving latest Watchman release from GitHub..."

    local download_url
    download_url="$(
        curl -fsSL "https://api.github.com/repos/facebook/watchman/releases/latest" \
        | grep -o "\"browser_download_url\": \"[^\"]*${os_tag}[^\"]*\.zip\"" \
        | head -1 \
        | sed 's/.*": "//;s/"//'
    )"

    if [[ -z "${download_url}" ]]; then
        log_error "Watchman: could not find a binary release URL for '${os_tag}'."
        return 1
    fi

    log_info "Downloading Watchman from: ${download_url}"

    tmp_dir="$(mktemp -d)"
    zip_path="${tmp_dir}/watchman.zip"

    if ! curl -fsSL -o "${zip_path}" "${download_url}"; then
        log_error "Watchman: download failed."
        rm -rf "${tmp_dir}"
        return 1
    fi

    log_info "Extracting Watchman archive..."
    if ! unzip -q "${zip_path}" -d "${tmp_dir}"; then
        log_error "Watchman: failed to extract archive."
        rm -rf "${tmp_dir}"
        return 1
    fi

    # The zip contains a top-level directory; find the watchman binary inside it.
    bin_src="$(find "${tmp_dir}" -type f -name "watchman" | head -1)"

    if [[ -z "${bin_src}" ]]; then
        log_error "Watchman: binary not found inside the downloaded archive."
        rm -rf "${tmp_dir}"
        return 1
    fi

    log_info "Installing Watchman binary to /usr/local/bin/watchman..."
    sudo install -m 0755 "${bin_src}" /usr/local/bin/watchman

    rm -rf "${tmp_dir}"
}


# install_watchman
# Installs Watchman using the platform-appropriate method:
#   macOS  : brew install watchman
#   Debian : Official binary release from GitHub releases
#   Fedora : dnf install watchman
#   Arch   : AUR via pacman (yay/paru)
# Parameters: None
# Returns: None
install_watchman() {
    if is_watchman_installed; then
        log_info "Watchman is already installed."
        print_watchman_version
        return 0
    fi

    log_step "Installing Watchman..."

    local os
    os="$(detect_os)"

    case "${os}" in
        macos)
            log_info "Installing Watchman via Homebrew..."
            install_pkg watchman
            ;;
        debian)
            log_info "Installing Watchman via official binary release..."
            _install_watchman_debian
            ;;
        fedora)
            log_info "Installing Watchman via dnf..."
            install_pkg watchman
            ;;
        arch)
            log_info "Installing Watchman via AUR..."
            install_pkg watchman
            ;;
        *)
            log_error "Watchman: unsupported OS '${os}'."
            return 1
            ;;
    esac

    if is_watchman_installed; then
        log_success "Watchman installation completed."
        print_watchman_version
    else
        log_error "Watchman installation failed."
        return 1
    fi
}


# print_watchman_version
# Prints the currently installed Watchman version.
# Parameters: None
# Returns: None
print_watchman_version() {
    log_info "Watchman version: $(watchman --version)"
}


export -f is_watchman_installed
export -f _install_watchman_debian
export -f install_watchman
export -f print_watchman_version


# Call the install function if this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_watchman
fi
