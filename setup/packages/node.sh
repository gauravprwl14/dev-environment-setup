#!/bin/bash

# packages/node.sh — Cross-platform Node.js installer via nvm
#
# Installs nvm using the official curl-based install script (works on both
# macOS and Linux without any Homebrew dependency), then uses nvm to install
# and manage Node.js versions.

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/update_shell_rc.sh"


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh"
NVM_SH="$HOME/.nvm/nvm.sh"


# ---------------------------------------------------------------------------
# is_nvm_installed
# Returns 0 if nvm is installed (i.e. $HOME/.nvm/nvm.sh exists), 1 otherwise.
# ---------------------------------------------------------------------------
is_nvm_installed() {
    [ -s "$HOME/.nvm/nvm.sh" ]
}


# ---------------------------------------------------------------------------
# install_nvm
# Installs nvm via the official curl script if not already present, sources
# it into the current shell session, and persists the init lines to the shell
# rc file.
# ---------------------------------------------------------------------------
install_nvm() {
    if is_nvm_installed; then
        log_info "nvm is already installed at $HOME/.nvm/nvm.sh"
    else
        log_step "Installing nvm via curl..."

        if ! command -v curl &> /dev/null; then
            log_error "curl is required to install nvm but was not found on PATH."
            return 1
        fi

        curl -o- "$NVM_INSTALL_URL" | bash

        if [ $? -ne 0 ]; then
            log_error "nvm installation failed."
            return 1
        fi

        log_success "nvm installed successfully."
    fi

    # Source nvm into the current shell session so subsequent calls work
    # without requiring the user to open a new shell.
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    \. "$NVM_SH"

    # Persist the nvm initialisation block to the shell rc file so new shells
    # automatically load nvm.
    log_info "Persisting nvm init lines to shell rc..."
    add_path_to_shell_rc 'export NVM_DIR="$HOME/.nvm"'
    add_path_to_shell_rc '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
    add_path_to_shell_rc '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
}


# ---------------------------------------------------------------------------
# is_node_installed [version]
# Checks whether the requested Node.js version is installed via nvm.
# Parameters:
#   $1  Node.js version alias or semver (optional, default: lts/*)
# Returns: 0 if installed, 1 otherwise.
# ---------------------------------------------------------------------------
is_node_installed() {
    local version="${1:-lts/*}"

    if ! is_nvm_installed; then
        log_warn "nvm is not installed; cannot check for Node.js."
        return 1
    fi

    # Ensure nvm is loaded in the current shell.
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    \. "$NVM_SH"

    if nvm ls "$version" &> /dev/null; then
        log_info "Node.js version '$version' is already installed."
        return 0
    else
        log_info "Node.js version '$version' is not installed."
        return 1
    fi
}


# ---------------------------------------------------------------------------
# install_node [version]
# Ensures nvm is installed, then installs the requested Node.js version and
# sets it as the nvm default alias.
# Parameters:
#   $1  Node.js version alias or semver (optional, default: lts/*)
# Returns: None
# ---------------------------------------------------------------------------
install_node() {
    local version="${1:-lts/*}"

    log_step "Setting up Node.js ($version)..."

    # Ensure nvm is installed (and sourced) before proceeding.
    install_nvm || return 1

    if is_node_installed "$version"; then
        log_success "Node.js version '$version' is already installed — nothing to do."
        return 0
    fi

    log_info "Installing Node.js version '$version' via nvm..."
    nvm install "${version}"

    if [ $? -ne 0 ]; then
        log_error "Failed to install Node.js version '$version'."
        return 1
    fi

    log_info "Setting Node.js version '$version' as the nvm default..."
    nvm alias default "${version}"
    nvm use default

    log_success "Node.js version '$version' installed and set as default."
}


# ---------------------------------------------------------------------------
# Export all public functions
# ---------------------------------------------------------------------------
export -f is_nvm_installed
export -f install_nvm
export -f is_node_installed
export -f install_node


# ---------------------------------------------------------------------------
# BASH_SOURCE guard — run install_node when executed directly
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_node "${1:-}"
fi
