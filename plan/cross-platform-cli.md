# Plan: Cross-Platform CLI Refactor

**Branch:** `feature/cross-platform-cli`
**Goal:** Extend the macOS-only setup scripts to support Linux (Ubuntu/Debian, Fedora, Arch) and expose everything through a proper CLI with flags and an interactive menu.

---

## Problem Statement

The current codebase has three core issues:

1. **macOS-only** — every script calls `brew` directly, hardcodes `/opt/homebrew/`, uses `open /Applications/`, and uses BSD `sed -i ''` which fails on Linux.
2. **No CLI** — `main.sh` is a flat bash script with lines commented in/out by hand. There is no way to select packages, run a dry-run, or get help.
3. **No abstraction** — package scripts reach directly for the package manager, making it impossible to swap in `apt` or `dnf` without rewriting every file.

---

## Target State

```
./main.sh                     # interactive checkbox menu
./main.sh --all               # install everything
./main.sh --install node,docker,postgres
./main.sh --list              # print available packages
./main.sh --dry-run --all     # preview without executing
./main.sh --help
```

Works on macOS (Homebrew), Ubuntu/Debian (apt), Fedora (dnf), Arch (pacman).

---

## Phases

---

### Phase 1 — Foundation Layer

**Goal:** Build the shared libraries everything else will depend on. No existing scripts are changed yet.

#### 1.1 `setup/lib/detect_os.sh`

```bash
detect_os()
# Returns one of: macos | debian | fedora | arch | unknown
# Uses uname + /etc/os-release
```

#### 1.2 `setup/lib/logger.sh`

```bash
log_info    "message"    # blue
log_success "message"    # green
log_warn    "message"    # yellow
log_error   "message"    # red
```

No dependencies. Pure bash color codes.

#### 1.3 `setup/lib/pkg.sh`

```bash
install_pkg  <name>    # brew / apt / dnf / pacman
install_cask <name>    # brew --cask / flatpak / snap fallback
add_service  <name>    # brew services start / systemctl enable --now
remove_pkg   <name>    # uninstall via correct manager
is_pkg_installed <name>
```

Sources `detect_os.sh` internally.

#### 1.4 `setup/utils/update_shell_rc.sh` (replaces `update_zshrc.sh`)

```bash
get_rc_file()                     # returns ~/.zshrc or ~/.bashrc based on $SHELL
portable_sed_inplace <args>       # calls sed -i (GNU) or sed -i '' (BSD)
add_to_shell_rc <var> <value>     # cross-platform replacement for update_zshrc()
add_path_to_shell_rc <path>       # appends to PATH in rc file
```

Keeps backward-compatible exports so existing scripts don't break immediately.

---

### Phase 2 — Platform Bootstrap Scripts

**Goal:** Isolate the platform-specific bootstrap (package manager setup) into `platform/`.

#### 2.1 `setup/platform/macos/homebrew.sh`

Moved from `setup/sdk/homebrew.sh`. No logic changes, just new path.

#### 2.2 `setup/platform/macos/xcode.sh`

Moved from `setup/sdk/xcode.sh`.

#### 2.3 `setup/platform/macos/mas.sh`

Moved from `setup/sdk/mas.sh`.

#### 2.4 `setup/platform/linux/apt.sh`

```bash
bootstrap_apt()
# Update apt, install curl, git, build-essential, software-properties-common
# Sets up flatpak if GUI apps are needed
```

#### 2.5 `setup/platform/linux/dnf.sh`

```bash
bootstrap_dnf()
# Fedora bootstrap: update dnf, install curl git make gcc
```

#### 2.6 `setup/platform/linux/snap.sh`

```bash
install_snap_pkg  <name>
install_snap_classic <name>   # --classic flag
```

---

### Phase 3 — Migrate Package Scripts

**Goal:** Rewrite each package script to use `lib/pkg.sh` and `lib/detect_os.sh` instead of calling `brew` directly. Files move from `setup/sdk/` to `setup/packages/`.

For each package, the pattern is:

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"

is_<name>_installed() { is_pkg_installed "<name>"; }

install_<name>() {
    if is_<name>_installed; then
        log_warn "<Name> already installed, skipping."
        return 0
    fi
    log_info "Installing <Name>..."
    case "$(detect_os)" in
        macos)  install_pkg <brew-name> ;;
        debian) install_pkg <apt-name>  ;;
        fedora) install_pkg <dnf-name>  ;;
        arch)   install_pkg <pacman-name> ;;
    esac
    log_success "<Name> installed."
}

export -f is_<name>_installed
export -f install_<name>

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_<name>
fi
```

#### Package migration list

| Old path | New path | Notes |
|---|---|---|
| `sdk/node.sh` | `packages/node.sh` | Use nvm on both platforms |
| `sdk/yarn.sh` | `packages/yarn.sh` | npm install -g yarn on Linux |
| `sdk/docker.sh` | `packages/docker.sh` | apt/dnf + systemctl on Linux |
| `sdk/java.sh` | `packages/java.sh` | sdkman on both platforms |
| `sdk/flutter.sh` | `packages/flutter.sh` | snap install flutter on Linux |
| `sdk/dart.sh` | `packages/dart.sh` | apt repo on Linux |
| `sdk/fvm.sh` | `packages/fvm.sh` | pub global on both |
| `sdk/miniconda.sh` | `packages/miniconda.sh` | Same installer URL, both platforms |
| `sdk/cocoapods.sh` | `packages/cocoapods.sh` | macOS-only, guarded |
| `sdk/watchman.sh` | `packages/watchman.sh` | brew / apt on Linux |
| `sdk/apps/cursor.sh` | `packages/apps/cursor.sh` | cask / deb download on Linux |
| `sdk/apps/podman.sh` | `packages/apps/podman.sh` | brew / apt on Linux, no machine on Linux |
| `sdk/apps/postman.sh` | `packages/apps/postman.sh` | cask / snap on Linux |
| `sdk/apps/obsidian.sh` | `packages/apps/obsidian.sh` | cask / flatpak on Linux |
| `sdk/apps/figma.sh` | `packages/apps/figma.sh` | cask / flatpak on Linux |
| `sdk/apps/openvpn.sh` | `packages/apps/openvpn.sh` | cask / apt on Linux |
| `sdk/apps/db/postgres.sh` | `packages/apps/db/postgres.sh` | brew / apt on Linux + systemctl |
| `sdk/apps/db/mysql.sh` | `packages/apps/db/mysql.sh` | brew / apt on Linux + systemctl |
| `sdk/apps/db/mongodb.sh` | `packages/apps/db/mongodb.sh` | brew tap / apt repo on Linux |
| `sdk/apps/redis.sh` | `packages/apps/redis.sh` | brew / apt + systemctl |

---

### Phase 4 — CLI Entry Point (`main.sh`)

**Goal:** Replace the flat commented-out script with a proper CLI.

#### 4.1 Package Registry

```bash
# Associative array: key=name, value=script path
declare -A PACKAGES=(
    [node]="packages/node.sh"
    [yarn]="packages/yarn.sh"
    [docker]="packages/docker.sh"
    [java]="packages/java.sh"
    [flutter]="packages/flutter.sh"
    [postgres]="packages/apps/db/postgres.sh"
    [mysql]="packages/apps/db/mysql.sh"
    [redis]="packages/apps/redis.sh"
    [cursor]="packages/apps/cursor.sh"
    [podman]="packages/apps/podman.sh"
    [postman]="packages/apps/postman.sh"
    [obsidian]="packages/apps/obsidian.sh"
)
```

#### 4.2 Argument Parsing

```bash
parse_args() {
    MODE="interactive"
    DRY_RUN=false
    SELECTED_PACKAGES=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)       MODE="all" ;;
            --install)   MODE="select"; IFS=',' read -ra SELECTED_PACKAGES <<< "$2"; shift ;;
            --list)      list_packages; exit 0 ;;
            --dry-run)   DRY_RUN=true ;;
            --help|-h)   show_help; exit 0 ;;
            *)           log_error "Unknown option: $1"; show_help; exit 1 ;;
        esac
        shift
    done
}
```

#### 4.3 Interactive Menu

Pure-bash arrow-key driven multi-select checklist. No external dependencies (no `dialog`, no `fzf` required — but can use them if available).

```
  Dev Environment Setup
  OS: macOS (Apple Silicon)
  ─────────────────────────────
  [ ] node          Node.js via nvm
  [x] yarn          Yarn package manager
  [ ] docker        Docker Desktop
  [x] postgres      PostgreSQL 18
  [ ] mysql         MySQL
  [ ] redis         Redis
  [ ] cursor        Cursor IDE
  [ ] podman        Podman + machine
  ─────────────────────────────
  SPACE to toggle, ENTER to install, q to quit
```

#### 4.4 Install Runner

```bash
run_install() {
    local pkg="$1"
    local script="${PACKAGES[$pkg]}"

    if [[ -z "$script" ]]; then
        log_error "Unknown package: $pkg"
        return 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[dry-run] Would install: $pkg"
        return 0
    fi

    log_info "Installing $pkg..."
    bash "$script"
}
```

---

### Phase 5 — Testing & Validation

#### 5.1 macOS smoke test
Run `./main.sh --dry-run --all` on macOS. Verify all paths resolve and no Linux-only calls appear.

#### 5.2 Linux smoke test
Run inside a Docker container:
```bash
docker run --rm -it ubuntu:22.04 bash
# inside container:
apt-get update && apt-get install -y git curl bash
git clone <repo> && cd dev-environment-setup/setup
./main.sh --dry-run --all
```

#### 5.3 Per-package test
Each script can be run individually and should exit 0 in dry-run mode on both platforms.

---

## File Change Summary

| Action | Files |
|---|---|
| New | `lib/detect_os.sh`, `lib/logger.sh`, `lib/pkg.sh` |
| New | `platform/linux/apt.sh`, `platform/linux/dnf.sh`, `platform/linux/snap.sh` |
| New | `plan/cross-platform-cli.md`, `CLAUDE.md` |
| Moved + updated | All `sdk/*.sh` → `packages/*.sh` |
| Moved + updated | All `sdk/apps/*.sh` → `packages/apps/*.sh` |
| Moved | `sdk/homebrew.sh` → `platform/macos/homebrew.sh` |
| Moved | `sdk/xcode.sh` → `platform/macos/xcode.sh` |
| Moved | `sdk/mas.sh` → `platform/macos/mas.sh` |
| Updated | `utils/update_zshrc.sh` → `utils/update_shell_rc.sh` |
| Rewritten | `main.sh` — full CLI |

---

## Out of Scope (This Branch)

- Windows / WSL support
- GUI installer (Electron, etc.)
- Package version pinning / lock files
- Automated CI on Linux runners (follow-up)
