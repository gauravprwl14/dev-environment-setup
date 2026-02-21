#!/bin/bash

# packages/miniconda.sh — Cross-platform Miniconda installer (macOS + Linux)
# Supports arm64 and x86_64 on both platforms.
# Safe to source or execute directly.

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/update_shell_rc.sh"

MINICONDA_BASE_URL="https://repo.anaconda.com/miniconda"
MINICONDA_INSTALL_DIR="$HOME/miniconda3"

# ---------------------------------------------------------------------------
# is_conda_installed
# Returns 0 if the `conda` command is available on PATH, 1 otherwise.
# ---------------------------------------------------------------------------
is_conda_installed() {
    if command -v conda &>/dev/null; then
        log_info "conda is already installed: $(conda --version)"
        return 0
    else
        log_info "conda is not installed."
        return 1
    fi
}

# ---------------------------------------------------------------------------
# install_miniconda
# Downloads and silently installs the official Miniconda installer for the
# detected OS and architecture, then registers conda on PATH via the shell rc.
# ---------------------------------------------------------------------------
install_miniconda() {
    if is_conda_installed; then
        log_success "Miniconda is already installed. Skipping installation."
        return 0
    fi

    local os arch installer_name installer_url tmp_installer

    os="$(detect_os)"
    arch="$(detect_arch)"

    log_step "Selecting Miniconda installer for OS=${os} ARCH=${arch}"

    case "${os}" in
        macos)
            case "${arch}" in
                arm64)
                    installer_name="Miniconda3-latest-MacOSX-arm64.sh"
                    ;;
                x86_64)
                    installer_name="Miniconda3-latest-MacOSX-x86_64.sh"
                    ;;
                *)
                    log_error "Unsupported macOS architecture: ${arch}"
                    return 1
                    ;;
            esac
            ;;
        debian|fedora|arch|linux)
            case "${arch}" in
                x86_64)
                    installer_name="Miniconda3-latest-Linux-x86_64.sh"
                    ;;
                arm64)
                    installer_name="Miniconda3-latest-Linux-aarch64.sh"
                    ;;
                *)
                    log_error "Unsupported Linux architecture: ${arch}"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Unsupported operating system: ${os}"
            return 1
            ;;
    esac

    installer_url="${MINICONDA_BASE_URL}/${installer_name}"
    tmp_installer="$(mktemp /tmp/miniconda-installer-XXXXXX.sh)"

    log_step "Downloading Miniconda installer"
    log_info "URL: ${installer_url}"

    if command -v curl &>/dev/null; then
        curl -fsSL "${installer_url}" -o "${tmp_installer}"
    elif command -v wget &>/dev/null; then
        wget -qO "${tmp_installer}" "${installer_url}"
    else
        log_error "Neither curl nor wget is available. Cannot download Miniconda."
        rm -f "${tmp_installer}"
        return 1
    fi

    log_step "Installing Miniconda to ${MINICONDA_INSTALL_DIR}"
    bash "${tmp_installer}" -b -p "${MINICONDA_INSTALL_DIR}"
    local exit_code=$?

    rm -f "${tmp_installer}"

    if [[ ${exit_code} -ne 0 ]]; then
        log_error "Miniconda installer exited with code ${exit_code}."
        return 1
    fi

    log_step "Adding Miniconda to PATH in shell rc"
    add_path_to_shell_rc "${MINICONDA_INSTALL_DIR}/bin"

    log_step "Running conda init for the current shell"
    local shell_name
    shell_name="$(basename "${SHELL}")"
    "${MINICONDA_INSTALL_DIR}/bin/conda" init "${shell_name}"

    log_success "Miniconda installation completed."
    log_info "Restart your shell or run: source $(get_rc_file)"
}

# ---------------------------------------------------------------------------
# print_conda_version
# Prints the installed conda version.
# ---------------------------------------------------------------------------
print_conda_version() {
    if is_conda_installed; then
        log_info "$(conda --version)"
    else
        log_error "conda is not installed."
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Export functions for use in sourcing scripts
# ---------------------------------------------------------------------------
export -f is_conda_installed
export -f install_miniconda
export -f print_conda_version

# ---------------------------------------------------------------------------
# BASH_SOURCE guard — run installation when executed directly
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_miniconda
    print_conda_version
fi
