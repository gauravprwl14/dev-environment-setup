#!/bin/bash

# lib/logger.sh — Bash logging library for the dev-environment-setup CLI.
#
# Usage (source this file from any script):
#   source "$(dirname "${BASH_SOURCE[0]}")/../../lib/logger.sh"
#
# Log levels:
#   log_info    "message"   — blue    [INFO]  message
#   log_success "message"   — green   [OK]    message
#   log_warn    "message"   — yellow  [WARN]  message
#   log_error   "message"   — red     [ERROR] message  (stderr)
#   log_step    "message"   — bold cyan  ==> message   (section headers)
#   log_debug   "message"   — dim grey [DEBUG] message (only when DEBUG=true)
#
# Color codes are stripped automatically when stdout is not a TTY.


# ---------------------------------------------------------------------------
# Internal: resolve ANSI codes only when writing to a real terminal.
# Each variable is set to the escape sequence when stdout is a TTY, or to an
# empty string otherwise so that output piped to a file stays clean.
# ---------------------------------------------------------------------------
_logger_init_colors() {
    if [[ -t 1 ]]; then
        _LOG_RESET="\033[0m"
        _LOG_BOLD="\033[1m"
        _LOG_DIM="\033[2m"
        _LOG_BLUE="\033[34m"
        _LOG_GREEN="\033[32m"
        _LOG_YELLOW="\033[33m"
        _LOG_RED="\033[31m"
        _LOG_CYAN="\033[36m"
    else
        _LOG_RESET=""
        _LOG_BOLD=""
        _LOG_DIM=""
        _LOG_BLUE=""
        _LOG_GREEN=""
        _LOG_YELLOW=""
        _LOG_RED=""
        _LOG_CYAN=""
    fi
}

_logger_init_colors


# ---------------------------------------------------------------------------
# log_info "message"
# Prints an informational message in blue.
# ---------------------------------------------------------------------------
log_info() {
    printf "${_LOG_BLUE}[INFO]${_LOG_RESET} %s\n" "$*"
}


# ---------------------------------------------------------------------------
# log_success "message"
# Prints a success message in green.
# ---------------------------------------------------------------------------
log_success() {
    printf "${_LOG_GREEN}[OK]${_LOG_RESET} %s\n" "$*"
}


# ---------------------------------------------------------------------------
# log_warn "message"
# Prints a warning message in yellow.
# ---------------------------------------------------------------------------
log_warn() {
    printf "${_LOG_YELLOW}[WARN]${_LOG_RESET} %s\n" "$*"
}


# ---------------------------------------------------------------------------
# log_error "message"
# Prints an error message in red to stderr.
# ---------------------------------------------------------------------------
log_error() {
    printf "${_LOG_RED}[ERROR]${_LOG_RESET} %s\n" "$*" >&2
}


# ---------------------------------------------------------------------------
# log_step "message"
# Prints a bold cyan section header prefixed with ==>.
# ---------------------------------------------------------------------------
log_step() {
    printf "${_LOG_BOLD}${_LOG_CYAN}==> %s${_LOG_RESET}\n" "$*"
}


# ---------------------------------------------------------------------------
# log_debug "message"
# Prints a dim grey debug message — only when DEBUG=true.
# ---------------------------------------------------------------------------
log_debug() {
    if [[ "${DEBUG:-}" == "true" ]]; then
        printf "${_LOG_DIM}[DEBUG]${_LOG_RESET} %s\n" "$*"
    fi
}


# ---------------------------------------------------------------------------
# Export all public functions so they are available in subshells and sourced
# scripts throughout the setup CLI.
# ---------------------------------------------------------------------------
export -f _logger_init_colors
export -f log_info
export -f log_success
export -f log_warn
export -f log_error
export -f log_step
export -f log_debug


# ---------------------------------------------------------------------------
# Self-demo: run one example of every log level when executed directly.
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_step    "Logger self-demo"
    log_info    "This is an informational message"
    log_success "This is a success message"
    log_warn    "This is a warning message"
    log_error   "This is an error message"
    DEBUG=true \
    log_debug   "This is a debug message (visible because DEBUG=true)"
    log_debug   "This debug line is suppressed (DEBUG not set)"
fi
