#!/bin/bash

# detect_os.sh — OS and architecture detection library
# Safe to source or execute directly.


# Function to detect the current operating system family.
# Parameters: None
# Returns: prints one of: macos | debian | fedora | arch | linux | unknown
detect_os() {
    local kernel
    kernel="$(uname -s)"

    if [[ "${kernel}" == "Darwin" ]]; then
        echo "macos"
        return 0
    fi

    if [[ "${kernel}" == "Linux" ]]; then
        if [[ -f /etc/os-release ]]; then
            local id
            id="$(. /etc/os-release && echo "${ID}")"
            case "${id}" in
                ubuntu|debian|linuxmint)
                    echo "debian"
                    ;;
                fedora|rhel|centos|rocky)
                    echo "fedora"
                    ;;
                arch|manjaro)
                    echo "arch"
                    ;;
                *)
                    echo "linux"
                    ;;
            esac
        else
            echo "linux"
        fi
        return 0
    fi

    echo "unknown"
}


# Function to detect the current CPU architecture.
# Parameters: None
# Returns: prints one of: arm64 | x86_64 | unknown
detect_arch() {
    local machine
    machine="$(uname -m)"

    case "${machine}" in
        arm64|aarch64)
            echo "arm64"
            ;;
        x86_64|amd64)
            echo "x86_64"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}


# Function to check if the current OS is macOS.
# Parameters: None
# Returns: 0 if macOS, 1 otherwise
is_macos() {
    if [[ "$(detect_os)" == "macos" ]]; then
        return 0
    else
        return 1
    fi
}


# Function to check if the current OS is Linux (any variant).
# Parameters: None
# Returns: 0 if Linux, 1 otherwise
is_linux() {
    local os
    os="$(detect_os)"
    case "${os}" in
        debian|fedora|arch|linux)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}


# Function to check if the current OS is Debian-based (e.g. Ubuntu, Debian, Linux Mint).
# Parameters: None
# Returns: 0 if Debian-based, 1 otherwise
is_debian_based() {
    if [[ "$(detect_os)" == "debian" ]]; then
        return 0
    else
        return 1
    fi
}


# Function to check if the current OS is Fedora-based (e.g. Fedora, RHEL, CentOS, Rocky).
# Parameters: None
# Returns: 0 if Fedora-based, 1 otherwise
is_fedora_based() {
    if [[ "$(detect_os)" == "fedora" ]]; then
        return 0
    else
        return 1
    fi
}


# Function to print a human-readable summary of the detected OS and architecture.
# Parameters: None
# Returns: None
print_os_info() {
    local os arch
    os="$(detect_os)"
    arch="$(detect_arch)"
    echo "OS: ${os} | Architecture: ${arch}"
}


export -f detect_os
export -f detect_arch
export -f is_macos
export -f is_linux
export -f is_debian_based
export -f is_fedora_based
export -f print_os_info


# Print OS info if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    print_os_info
fi
