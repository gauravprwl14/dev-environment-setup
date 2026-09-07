#!/bin/bash
set -euo pipefail

# Change to the directory containing this script so all relative paths work.
cd "$(dirname "${BASH_SOURCE[0]}")"

source "lib/detect_os.sh"
source "lib/logger.sh"


# ---------------------------------------------------------------------------
# Package Registry
# ---------------------------------------------------------------------------

declare -A PACKAGES=(
    [node]="packages/node.sh"
    [python3]="packages/python3.sh"
    [yarn]="packages/yarn.sh"
    [pnpm]="packages/pnpm.sh"
    [docker]="packages/docker.sh"
    [java]="packages/java.sh"
    [flutter]="packages/flutter.sh"
    [dart]="packages/dart.sh"
    [fvm]="packages/fvm.sh"
    [watchman]="packages/watchman.sh"
    [miniconda]="packages/miniconda.sh"
    [cocoapods]="packages/cocoapods.sh"
    [cmake]="packages/cmake.sh"
    [fzf]="packages/fzf.sh"
    [yt-dlp]="packages/yt-dlp.sh"
    [postgres]="packages/apps/db/postgres.sh"
    [mysql]="packages/apps/db/mysql.sh"
    [mongodb]="packages/apps/db/mongodb.sh"
    [redis]="packages/apps/redis.sh"
    [cursor]="packages/apps/cursor.sh"
    [android-studio]="packages/apps/android-studio.sh"
    [podman]="packages/apps/podman.sh"
    [podman-compose]="packages/apps/podman-compose.sh"
    [podman-desktop]="packages/apps/podman-desktop.sh"
    [postman]="packages/apps/postman.sh"
    [obsidian]="packages/apps/obsidian.sh"
    [figma]="packages/apps/figma.sh"
    [openvpn]="packages/apps/openvpn.sh"
    [vlc]="packages/apps/vlc.sh"
    [telegram]="packages/apps/telegram.sh"
    [discord]="packages/apps/discord.sh"
    [slack]="packages/apps/slack.sh"
)

declare -A PACKAGE_DESCS=(
    [node]="Node.js via nvm (cross-platform)"
    [python3]="Python 3 (with pip/venv where available)"
    [yarn]="Yarn package manager"
    [pnpm]="pnpm package manager"
    [docker]="Docker (Desktop on macOS, Engine on Linux)"
    [java]="Java JDK via SDKMAN"
    [flutter]="Flutter SDK"
    [dart]="Dart SDK"
    [fvm]="Flutter Version Manager"
    [watchman]="Watchman file watcher (Meta)"
    [miniconda]="Miniconda (Python)"
    [cocoapods]="CocoaPods (macOS only)"
    [cmake]="CMake build system"
    [fzf]="fzf fuzzy finder (enables enhanced interactive menu)"
    [yt-dlp]="yt-dlp video/audio downloader (youtube-dl fork)"
    [postgres]="PostgreSQL 17"
    [mysql]="MySQL"
    [mongodb]="MongoDB 8.0"
    [redis]="Redis"
    [cursor]="Cursor IDE"
    [android-studio]="Android Studio IDE (SDK/emulator provisioning not included)"
    [podman]="Podman container engine"
    [podman-compose]="Podman Compose (docker-compose alternative)"
    [podman-desktop]="Podman Desktop GUI app"
    [postman]="Postman API client"
    [obsidian]="Obsidian note-taking app"
    [figma]="Figma design tool"
    [openvpn]="OpenVPN"
    [vlc]="VLC media player"
    [telegram]="Telegram Desktop"
    [discord]="Discord chat app"
    [slack]="Slack team messaging app"
)

# Ordered list of package keys for consistent display in menus and tables.
PACKAGE_KEYS=(
    node python3 yarn pnpm docker java flutter dart fvm watchman miniconda cocoapods cmake fzf yt-dlp
    postgres mysql mongodb redis cursor android-studio podman podman-compose podman-desktop postman obsidian figma openvpn vlc telegram discord slack
)

# Runtime state
MODE="interactive"
DRY_RUN="false"
SELECTED_PACKAGES=()


# ---------------------------------------------------------------------------
# show_help
# ---------------------------------------------------------------------------

show_help() {
    log_info "Usage: ./main.sh [OPTIONS]"
    printf "\n"
    printf "Options:\n"
    printf "  (no args)              Interactive selection menu\n"
    printf "  --all                  Install all packages\n"
    printf "  --install <list>       Comma-separated package names (e.g. node,docker,postgres)\n"
    printf "  --list                 List all available packages and exit\n"
    printf "  --dry-run              Preview installs without executing\n"
    printf "  --help, -h             Show this help\n"
    printf "\n"
    printf "Examples:\n"
    printf "  ./main.sh\n"
    printf "  ./main.sh --all\n"
    printf "  ./main.sh --install node,docker,postgres\n"
    printf "  ./main.sh --dry-run --all\n"
}


# ---------------------------------------------------------------------------
# list_packages
# ---------------------------------------------------------------------------

list_packages() {
    printf "\n"
    log_step "Available Packages"
    printf "  %-16s  %s\n" "NAME" "DESCRIPTION"
    printf "  %-16s  %s\n" "────────────────" "──────────────────────────────────────────"
    for key in "${PACKAGE_KEYS[@]}"; do
        printf "  %-16s  %s\n" "$key" "${PACKAGE_DESCS[$key]}"
    done
    printf "\n"
}


# ---------------------------------------------------------------------------
# parse_args
# ---------------------------------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --list)
                list_packages
                exit 0
                ;;
            --all)
                MODE="all"
                shift
                ;;
            --install)
                if [[ -z "${2:-}" ]]; then
                    log_error "--install requires a comma-separated list of package names."
                    exit 1
                fi
                MODE="select"
                IFS=',' read -ra SELECTED_PACKAGES <<< "$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}


# ---------------------------------------------------------------------------
# run_install
# ---------------------------------------------------------------------------

run_install() {
    local pkg="$1"
    local script="${PACKAGES[$pkg]:-}"

    if [[ -z "$script" ]]; then
        log_error "Unknown package: $pkg"
        return 1
    fi

    if [[ ! -f "$script" ]]; then
        log_error "Script not found: $script"
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[dry-run] Would install: $pkg — ${PACKAGE_DESCS[$pkg]}"
        return 0
    fi

    log_step "Installing $pkg..."
    bash "$script"
    log_success "$pkg installation complete."
}


# ---------------------------------------------------------------------------
# bootstrap_platform
# ---------------------------------------------------------------------------

bootstrap_platform() {
    local os
    os="$(detect_os)"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[dry-run] Would bootstrap platform: $os"
        return 0
    fi

    case "$os" in
        macos)
            log_step "Bootstrapping macOS (Homebrew)"
            source "platform/macos/homebrew.sh"
            install_homebrew
            ;;
        debian)
            log_step "Bootstrapping Debian/Ubuntu (APT)"
            source "platform/linux/apt.sh"
            bootstrap_apt
            ;;
        fedora)
            log_step "Bootstrapping Fedora/RHEL (DNF)"
            source "platform/linux/dnf.sh"
            bootstrap_dnf
            ;;
        arch)
            log_step "Bootstrapping Arch Linux (pacman)"
            log_info "Refreshing pacman package database..."
            sudo pacman -Sy
            log_success "pacman database refreshed."
            ;;
        *)
            log_warn "Unrecognised OS '$os' — skipping platform bootstrap."
            ;;
    esac
}


# ---------------------------------------------------------------------------
# interactive_menu
# ---------------------------------------------------------------------------

interactive_menu() {
    printf "\n"
    log_step "Dev Environment Setup"
    log_info "OS: $(detect_os) | Arch: $(detect_arch)"
    printf "\n"

    # Prefer fzf when it is available for an enhanced multi-select experience.
    if command -v fzf &> /dev/null; then
        _interactive_menu_fzf
    else
        _interactive_menu_bash
    fi
}


# fzf-based multi-select menu.
_interactive_menu_fzf() {
    log_info "fzf detected — use TAB to multi-select, ENTER to confirm."
    printf "\n"

    local lines=()
    for key in "${PACKAGE_KEYS[@]}"; do
        lines+=("$(printf "%-16s  %s" "$key" "${PACKAGE_DESCS[$key]}")")
    done

    local chosen
    chosen="$(printf '%s\n' "${lines[@]}" | fzf \
        --multi \
        --prompt="Select packages > " \
        --header="TAB to select/deselect, ENTER to confirm, CTRL-C to cancel" \
        --height=60% \
        --border \
        --ansi)" || {
        log_warn "Selection cancelled."
        exit 0
    }

    if [[ -z "$chosen" ]]; then
        log_warn "No packages selected. Exiting."
        exit 0
    fi

    while IFS= read -r line; do
        local pkg
        pkg="$(printf '%s' "$line" | awk '{print $1}')"
        SELECTED_PACKAGES+=("$pkg")
    done <<< "$chosen"

    _confirm_and_install
}


# Pure-bash numbered list menu (no external deps required).
_interactive_menu_bash() {
    printf "  ─────────────────────────────────────────\n"
    printf "  Available Packages:\n"

    local i=1
    for key in "${PACKAGE_KEYS[@]}"; do
        printf "  %2d) %-16s %s\n" "$i" "$key" "${PACKAGE_DESCS[$key]}"
        (( i++ ))
    done

    printf "  ─────────────────────────────────────────\n"
    printf "  Enter numbers or names (comma-separated), or 'all':\n"
    printf "  > "

    local input
    read -r input

    if [[ -z "$input" ]]; then
        log_warn "No input provided. Exiting."
        exit 0
    fi

    if [[ "$input" == "all" ]]; then
        SELECTED_PACKAGES=("${PACKAGE_KEYS[@]}")
    else
        # Accept comma-separated numbers, names, or a mix of both.
        IFS=',' read -ra tokens <<< "$input"
        for token in "${tokens[@]}"; do
            # Strip surrounding whitespace.
            token="${token#"${token%%[![:space:]]*}"}"
            token="${token%"${token##*[![:space:]]}"}"

            if [[ "$token" =~ ^[0-9]+$ ]]; then
                # Numeric input — convert 1-based index to key.
                local idx=$(( token - 1 ))
                if (( idx < 0 || idx >= ${#PACKAGE_KEYS[@]} )); then
                    log_error "Invalid number: $token (valid range: 1–${#PACKAGE_KEYS[@]})"
                    exit 1
                fi
                SELECTED_PACKAGES+=("${PACKAGE_KEYS[$idx]}")
            else
                # Name input — validate against the registry.
                if [[ -z "${PACKAGES[$token]:-}" ]]; then
                    log_error "Unknown package name: '$token'"
                    exit 1
                fi
                SELECTED_PACKAGES+=("$token")
            fi
        done
    fi

    if [[ ${#SELECTED_PACKAGES[@]} -eq 0 ]]; then
        log_warn "No packages selected. Exiting."
        exit 0
    fi

    _confirm_and_install
}


# Show a summary of what will be installed and ask the user to confirm.
_confirm_and_install() {
    printf "\n"
    log_info "Selected packages:"
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        printf "    • %-16s %s\n" "$pkg" "${PACKAGE_DESCS[$pkg]}"
    done
    printf "\n"

    printf "  Proceed with installation? [y/N] "
    local answer
    read -r answer

    case "$answer" in
        y|Y|yes|YES)
            bootstrap_platform
            for pkg in "${SELECTED_PACKAGES[@]}"; do
                run_install "$pkg"
            done
            ;;
        *)
            log_warn "Installation cancelled."
            exit 0
            ;;
    esac
}


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

main() {
    parse_args "$@"

    log_step "Dev Environment Setup"
    log_info "OS: $(detect_os) | Arch: $(detect_arch)"

    case "$MODE" in
        all)
            bootstrap_platform
            for pkg in "${PACKAGE_KEYS[@]}"; do
                run_install "$pkg"
            done
            ;;
        select)
            bootstrap_platform
            for pkg in "${SELECTED_PACKAGES[@]}"; do
                run_install "$pkg"
            done
            ;;
        interactive)
            interactive_menu
            ;;
    esac

    log_success "All done!"
}

main "$@"
