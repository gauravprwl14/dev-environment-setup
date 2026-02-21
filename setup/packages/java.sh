#!/bin/bash

# packages/java.sh — Cross-platform Java installation via SDKMAN
# Works on macOS and Linux (Debian, Fedora, Arch).
# SDKMAN handles Java version management uniformly across platforms.

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/update_shell_rc.sh"

# Default Java version to install via SDKMAN (Eclipse Temurin LTS)
DEFAULT_JAVA_VERSION="21.0.2-tem"


# ---------------------------------------------------------------------------
# is_sdkman_installed
# Returns 0 if the SDKMAN init script is present, 1 otherwise.
# ---------------------------------------------------------------------------
is_sdkman_installed() {
    if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        log_info "SDKMAN is installed."
        return 0
    else
        log_info "SDKMAN is not installed."
        return 1
    fi
}


# ---------------------------------------------------------------------------
# install_sdkman
# Downloads and runs the official SDKMAN installer, then sources the init
# script so that the 'sdk' command is available in the current shell session.
# ---------------------------------------------------------------------------
install_sdkman() {
    if is_sdkman_installed; then
        log_success "SDKMAN is already installed — skipping."
        return 0
    fi

    log_step "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash

    if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        # shellcheck disable=SC1090
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        log_success "SDKMAN installation completed and initialised."
    else
        log_error "SDKMAN installation failed — init script not found."
        return 1
    fi
}


# ---------------------------------------------------------------------------
# is_java_installed
# Returns 0 if the 'java' binary is available on PATH, 1 otherwise.
# ---------------------------------------------------------------------------
is_java_installed() {
    if command -v java &> /dev/null; then
        log_info "Java is already installed."
        return 0
    else
        log_info "Java is not installed."
        return 1
    fi
}


# ---------------------------------------------------------------------------
# install_java [version]
# Installs Java via SDKMAN using the specified version identifier, or the
# default (21.0.2-tem — Eclipse Temurin 21 LTS) when none is provided.
# Also registers JAVA_HOME in the shell rc file.
#
# Parameters:
#   $1  (optional) SDKMAN version string, e.g. "21.0.2-tem" or "17.0.9-tem"
# ---------------------------------------------------------------------------
install_java() {
    local version="${1:-$DEFAULT_JAVA_VERSION}"

    log_step "Installing Java ${version} via SDKMAN..."

    # Ensure SDKMAN is available
    install_sdkman || return 1

    # Source SDKMAN init in case we are running in a fresh shell context
    # shellcheck disable=SC1090
    source "$HOME/.sdkman/bin/sdkman-init.sh"

    if is_java_installed; then
        log_success "Java is already installed — skipping sdk install."
    else
        log_info "Running: sdk install java ${version}"
        sdk install java "${version}"

        if ! is_java_installed; then
            log_error "Java installation via SDKMAN failed."
            return 1
        fi

        log_success "Java ${version} installed successfully."
    fi

    # Register JAVA_HOME in the shell rc file
    local java_home
    java_home="$HOME/.sdkman/candidates/java/current"
    log_info "Registering JAVA_HOME=${java_home} in shell rc..."
    add_to_shell_rc "JAVA_HOME" "${java_home}"
}


# ---------------------------------------------------------------------------
# print_java_version
# Prints the currently active Java version to stdout.
# ---------------------------------------------------------------------------
print_java_version() {
    if ! is_java_installed; then
        log_warn "Java is not installed — cannot print version."
        return 1
    fi

    log_step "Java version:"
    java -version
}


# ---------------------------------------------------------------------------
# Export all public functions
# ---------------------------------------------------------------------------
export -f is_sdkman_installed
export -f install_sdkman
export -f is_java_installed
export -f install_java
export -f print_java_version


# ---------------------------------------------------------------------------
# BASH_SOURCE guard — run install_java when executed directly
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_java
fi
