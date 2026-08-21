# Architecture — dev-environment-setup

A cross-platform developer environment CLI that installs SDKs, CLI tools,
databases, and GUI applications on macOS and Linux (Ubuntu/Debian, Fedora,
Arch) through an interactive menu or command-line flags.

---

## 1. Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      main.sh  (CLI)                         │  ← Entry point
│  parse_args · bootstrap_platform · run_install · menus      │
├─────────────────────────────────────────────────────────────┤
│                     packages/*.sh                           │  ← Cross-platform installers
│  node  yarn  docker  java  flutter  dart  fvm  miniconda    │
│  cocoapods  watchman  postgres  mysql  mongodb  redis        │
│  cursor  podman  postman  obsidian  figma  openvpn          │
├──────────────────────────┬──────────────────────────────────┤
│       platform/          │            lib/                  │  ← Bootstrap + shared libs
│  macos/                  │  detect_os.sh                    │
│    homebrew.sh           │  pkg.sh                          │
│    xcode.sh              │  logger.sh                       │
│    mas.sh                │                                  │
│  linux/                  │  utils/                          │
│    apt.sh                │  update_shell_rc.sh              │
│    dnf.sh                │  change_permission.sh            │
│    snap.sh               │                                  │
└──────────────────────────┴──────────────────────────────────┘
            ↓                              ↓
   brew / apt-get / dnf          ~/.zshrc / ~/.bashrc
   pacman / flatpak /            ~/.profile
   snap / systemctl
```

Each layer depends only on the layers beneath it. Package scripts never reach
into `platform/` directly; the `lib/` layer is the only allowed downward
dependency from `packages/`.

---

## 2. Layer Descriptions

### 2.1 Entry Point — `setup/main.sh`

The single executable the user invokes. It owns:

- **Argument parsing** (`parse_args`) — interprets `--all`, `--install`,
  `--list`, `--dry-run`, and `--help` flags.
- **Package registry** — two associative arrays (`PACKAGES`, `PACKAGE_DESCS`)
  and an ordered key list (`PACKAGE_KEYS`) that map logical names such as
  `node` to their installer script paths.
- **Platform bootstrap** (`bootstrap_platform`) — detects the OS and sources
  the appropriate `platform/` script to ensure the base package manager is
  ready before any packages are installed.
- **Install runner** (`run_install`) — looks up the script for a package name,
  enforces `--dry-run` mode, and delegates to `bash <script>`.
- **Interactive menus** — a `fzf`-based multi-select when `fzf` is available,
  or a pure-bash numbered list fallback requiring no external dependencies.

`main.sh` is the only script that calls `bootstrap_platform`. All other scripts
assume the package manager is already present.

### 2.2 Package Scripts — `setup/packages/`

One file per installable unit. Each script:

- Sources `lib/detect_os.sh`, `lib/pkg.sh`, and `lib/logger.sh`.
- Exposes exactly two public functions: `is_<name>_installed` and
  `install_<name>`.
- Uses `case "$(detect_os)"` for any platform-specific variation (different
  package names, post-install steps, etc.).
- Guards direct execution with a `BASH_SOURCE` check so the file can be both
  sourced by `main.sh` and run standalone for testing.
- Is idempotent — calling it multiple times produces the same result.

GUI applications live under `packages/apps/`; database servers under
`packages/apps/db/`.

### 2.3 Platform Bootstrap — `setup/platform/`

Isolates first-time package-manager setup so package scripts never need to
worry about whether Homebrew or APT is installed.

| Directory | Script | Responsibility |
|---|---|---|
| `platform/macos/` | `homebrew.sh` | Install Homebrew if absent |
| `platform/macos/` | `xcode.sh` | Install Xcode Command Line Tools |
| `platform/macos/` | `mas.sh` | Install Mac App Store CLI |
| `platform/linux/` | `apt.sh` | `apt-get update`, install curl/git/build-essential |
| `platform/linux/` | `dnf.sh` | `dnf check-update`, install curl/git/make/gcc |
| `platform/linux/` | `snap.sh` | `install_snap_pkg` / `install_snap_classic` helpers |

These scripts are sourced by `bootstrap_platform` in `main.sh` and are not
called by any package script.

### 2.4 Shared Libraries — `setup/lib/`

Zero-dependency utilities that are sourced by every layer above them.

| File | Purpose |
|---|---|
| `detect_os.sh` | Returns a normalised OS token; also detects CPU architecture |
| `pkg.sh` | Translates `install_pkg` / `install_cask` / `add_service` calls to OS-specific commands |
| `logger.sh` | Coloured, TTY-aware output helpers |

### 2.5 Utilities — `setup/utils/`

| File | Purpose |
|---|---|
| `update_shell_rc.sh` | Cross-platform shell rc reader/writer (PATH, variable exports) |
| `change_permission.sh` | File permission helpers |

---

## 3. Key Design Principles

### 3.1 Single Responsibility

Each script installs exactly one thing. `node.sh` knows about Node; it knows
nothing about Docker. `main.sh` knows about orchestration; it knows nothing
about how individual tools are installed. This boundary is enforced through the
package registry: `main.sh` calls `bash packages/node.sh` — it never reaches
into `node.sh`'s internals.

### 3.2 Idempotency

Every package script checks whether the tool is already installed before
acting. The standard guard:

```bash
is_node_installed() { is_pkg_installed "node"; }

install_node() {
    if is_node_installed; then
        log_warn "Node already installed, skipping."
        return 0
    fi
    ...
}
```

`is_pkg_installed` (in `lib/pkg.sh`) uses `command -v` — a check that works
on every supported platform with no package-manager involvement.

Running `./main.sh --all` twice on the same machine is safe and fast.

### 3.3 OS Abstraction

Package scripts **never** call `brew`, `apt-get`, `dnf`, or `pacman` directly.
All package-manager interactions go through `lib/pkg.sh`. This means a package
script written for macOS works on Linux without modification — the abstraction
layer handles the translation.

Prohibited patterns in `packages/`:

```bash
# WRONG — never do this in a package script
brew install node
sudo apt-get install -y nodejs
open /Applications/Docker.app
sed -i '' ...
echo 'export PATH=...' >> ~/.zshrc
```

Correct patterns:

```bash
install_pkg "node"              # lib/pkg.sh resolves the manager
install_cask "docker"           # lib/pkg.sh resolves brew --cask / flatpak / snap
add_service "postgresql"        # lib/pkg.sh resolves brew services / systemctl
add_to_shell_rc "NODE_HOME" "$HOME/.nvm"   # utils/update_shell_rc.sh
portable_sed_inplace ...        # utils/update_shell_rc.sh
```

### 3.4 Graceful Degradation

Tools that are macOS-only (e.g., `cocoapods`) detect the OS and exit cleanly
on Linux rather than failing:

```bash
install_cocoapods() {
    if ! is_macos; then
        log_warn "CocoaPods is macOS only — skipping on $(detect_os)."
        return 0
    fi
    ...
}
```

This ensures `./main.sh --all` completes successfully on Linux without manual
exclusions.

---

## 4. Data Flow — `./main.sh --install node`

```
./main.sh --install node
        │
        ▼
parse_args()
  MODE="select"
  SELECTED_PACKAGES=("node")
        │
        ▼
main() dispatches on MODE="select"
        │
        ├─► bootstrap_platform()
        │       detect_os() → "debian"
        │       source platform/linux/apt.sh
        │       bootstrap_apt()           ← ensures apt is ready
        │
        └─► run_install("node")
                PACKAGES["node"] = "packages/node.sh"
                DRY_RUN="false"  → not a dry run
                log_step "Installing node..."
                bash packages/node.sh
                        │
                        ▼
                source lib/detect_os.sh
                source lib/pkg.sh
                source lib/logger.sh
                        │
                        ▼
                is_node_installed()
                  command -v node → not found
                        │
                        ▼
                install_node()
                  detect_os() → "debian"
                  install_pkg "nodejs"
                    └─► apt-get install -y nodejs
                  add_to_shell_rc "NVM_DIR" "$HOME/.nvm"
                    └─► get_rc_file() → ~/.bashrc
                        portable_sed_inplace appends export
                  log_success "Node installed."
```

At no point does `main.sh` know which package manager was used. At no point
does `packages/node.sh` know whether it was invoked by `main.sh` or run
directly.

---

## 5. OS Detection

`detect_os` in `setup/lib/detect_os.sh` is the authoritative source of OS
information for every script in the repository.

### Detection logic

```
detect_os()
  │
  ├─ uname -s == "Darwin"
  │     └─► echo "macos"
  │
  └─ uname -s == "Linux"
        │
        ├─ /etc/os-release exists?
        │     ID field:
        │       ubuntu | debian | linuxmint  → echo "debian"
        │       fedora | rhel | centos | rocky → echo "fedora"
        │       arch | manjaro               → echo "arch"
        │       (anything else)              → echo "linux"
        │
        └─ /etc/os-release absent           → echo "linux"

  (neither Darwin nor Linux)                → echo "unknown"
```

### Return values

| Token | Meaning |
|---|---|
| `macos` | Darwin (any Apple Silicon or Intel Mac) |
| `debian` | Ubuntu, Debian, Linux Mint |
| `fedora` | Fedora, RHEL, CentOS, Rocky Linux |
| `arch` | Arch Linux, Manjaro |
| `linux` | Any other Linux (generic fallback) |
| `unknown` | Not Darwin, not Linux |

### Architecture detection

`detect_arch` is a companion function that normalises `uname -m` output:

| `uname -m` | Returns |
|---|---|
| `arm64`, `aarch64` | `arm64` |
| `x86_64`, `amd64` | `x86_64` |
| anything else | `unknown` |

### Convenience predicates

The library also exports boolean helpers used by package scripts that need a
simple guard without a full `case` statement:

```bash
is_macos()        # returns 0 on macOS, 1 otherwise
is_linux()        # returns 0 on debian | fedora | arch | linux
is_debian_based() # returns 0 on debian
is_fedora_based() # returns 0 on fedora
```

All functions are exported with `export -f` so they survive into subshells
launched by `bash packages/node.sh`.

---

## 6. Package Manager Abstraction

`setup/lib/pkg.sh` is the translation layer between the logical operations
package scripts request and the concrete commands each OS requires. It sources
`detect_os.sh` internally; callers never need to check the OS themselves for
routine install/remove/service operations.

### Function reference

| Function | macOS | Debian/Ubuntu | Fedora/RHEL | Arch |
|---|---|---|---|---|
| `install_pkg <name>` | `brew install <name>` | `apt-get install -y <name>` | `dnf install -y <name>` | `pacman -S --noconfirm <name>` |
| `install_cask <name>` | `brew install --cask <name>` | `flatpak install -y flathub <name>` (snap fallback) | `flatpak install -y flathub <name>` (snap fallback) | `yay -S --noconfirm <name>` (paru fallback, then flatpak) |
| `remove_pkg <name>` | `brew uninstall <name>` | `apt-get remove -y <name>` | `dnf remove -y <name>` | `pacman -R --noconfirm <name>` |
| `update_pkg_manager` | `brew update` | `apt-get update` | `dnf check-update \|\| true` | `pacman -Sy` |
| `add_service <name>` | `brew services start <name>` | `systemctl enable --now <name>` | `systemctl enable --now <name>` | `systemctl enable --now <name>` |
| `stop_service <name>` | `brew services stop <name>` | `systemctl stop <name>` | `systemctl stop <name>` | `systemctl stop <name>` |
| `is_pkg_installed <name>` | `command -v <name>` | `command -v <name>` | `command -v <name>` | `command -v <name>` |
| `is_brew_pkg_installed <name>` | `brew list <name>` | returns 1 | returns 1 | returns 1 |

### `install_cask` resolution order

```
detect_os() == "macos"
  └─► brew install --cask

detect_os() == "debian" | "fedora"
  ├─ command -v flatpak  → flatpak install -y flathub
  └─ (else)              → snap install

detect_os() == "arch"
  ├─ command -v yay      → yay -S --noconfirm
  ├─ command -v paru     → paru -S --noconfirm
  ├─ command -v flatpak  → flatpak install -y flathub
  └─ (none found)        → error, return 1
```

All functions are exported with `export -f` so they are accessible in
subshells spawned by `run_install`.

---

## 7. Shell RC Management

`setup/utils/update_shell_rc.sh` provides all functionality for writing to the
user's shell startup file. **No other script may write directly to `.zshrc`,
`.bashrc`, or `.profile`.**

### RC file selection — `get_rc_file`

```bash
$SHELL contains "zsh"   → $HOME/.zshrc
$SHELL contains "bash"  → $HOME/.bashrc
(else)                  → $HOME/.profile
```

The result is computed at call time, not at source time, so it always reflects
the actual login shell of the user running the script.

### Portable in-place sed — `portable_sed_inplace`

The BSD `sed` shipped with macOS requires `sed -i ''` (empty-string extension
argument); GNU `sed` on Linux uses `sed -i` (no extra argument). Calling the
wrong form causes an immediate error on the other platform.

`portable_sed_inplace` detects the variant at runtime:

```bash
portable_sed_inplace() {
    if sed --version 2>&1 | grep -q GNU; then
        sed -i "$@"       # GNU sed (Linux)
    else
        sed -i '' "$@"    # BSD sed (macOS)
    fi
}
```

Package scripts pass their `sed` expression as arguments to this function
instead of calling `sed` directly.

### Managed sections

The rc file is divided into two named sections delineated by sentinel comments:

```
# Begin Variable section
export NVM_DIR=/home/user/.nvm
export JAVA_HOME=/usr/lib/jvm/java-21
# End Variable section

# Begin PATH section
export PATH=$PATH:$NVM_DIR
export PATH=$PATH:$JAVA_HOME/bin
# End PATH section
```

The sentinel lines are created on first use if absent. All subsequent writes
use `portable_sed_inplace` to insert lines immediately after `Begin Variable
section` or immediately before `End PATH section`.

### Public API

| Function | Signature | Effect |
|---|---|---|
| `get_rc_file` | `get_rc_file` | Prints path to the active rc file |
| `add_to_shell_rc` | `add_to_shell_rc <VAR> <value> [rc_file]` | Adds `export VAR=value` in Variable section and `export PATH=$PATH:$VAR` in PATH section; idempotent |
| `add_path_to_shell_rc` | `add_path_to_shell_rc <path> [rc_file]` | Appends a raw path literal to the PATH section; idempotent |
| `update_exported_variable` | `update_exported_variable <VAR> <value> [rc_file]` | Updates an existing `export VAR=...` in place, or inserts it; does not touch PATH section |
| `portable_sed_inplace` | `portable_sed_inplace <sed_args...>` | Runs `sed -i` (GNU) or `sed -i ''` (BSD) |
| `update_zshrc` | `update_zshrc <VAR> <value> [rc_file]` | Backward-compatibility alias for `add_to_shell_rc` |

---

## 8. Directory Reference

```
setup/
│
├── main.sh                        # CLI entry point; package registry; arg parsing;
│                                  # platform bootstrap; interactive menus
│
├── lib/
│   ├── detect_os.sh               # detect_os() → macos|debian|fedora|arch|linux|unknown
│   │                              # detect_arch() → arm64|x86_64|unknown
│   │                              # Convenience predicates: is_macos, is_linux, etc.
│   ├── pkg.sh                     # install_pkg / install_cask / remove_pkg /
│   │                              # add_service / stop_service / update_pkg_manager /
│   │                              # is_pkg_installed / is_brew_pkg_installed
│   └── logger.sh                  # log_info / log_success / log_warn / log_error /
│                                  # log_step / log_debug
│                                  # TTY-aware: strips ANSI codes when piped
│
├── utils/
│   ├── update_shell_rc.sh         # get_rc_file / add_to_shell_rc / add_path_to_shell_rc /
│   │                              # update_exported_variable / portable_sed_inplace
│   └── change_permission.sh       # File permission helpers
│
├── platform/
│   ├── macos/
│   │   ├── homebrew.sh            # install_homebrew — installs Homebrew if absent
│   │   ├── xcode.sh               # install Xcode Command Line Tools
│   │   └── mas.sh                 # install Mac App Store CLI
│   └── linux/
│       ├── apt.sh                 # bootstrap_apt — apt-get update + base dependencies
│       ├── dnf.sh                 # bootstrap_dnf — dnf + base dependencies
│       └── snap.sh                # install_snap_pkg / install_snap_classic helpers
│
└── packages/
    ├── node.sh                    # Node.js via nvm (both platforms)
    ├── yarn.sh                    # Yarn package manager
    ├── docker.sh                  # Docker Desktop (macOS) / Docker Engine (Linux)
    ├── java.sh                    # Java JDK via SDKMAN
    ├── flutter.sh                 # Flutter SDK
    ├── dart.sh                    # Dart SDK
    ├── fvm.sh                     # Flutter Version Manager
    ├── watchman.sh                # Watchman file watcher
    ├── miniconda.sh               # Miniconda (Python)
    ├── cocoapods.sh               # CocoaPods — macOS only, skips on Linux
    └── apps/
        ├── cursor.sh              # Cursor IDE — cask / deb download
        ├── podman.sh              # Podman — brew / apt; no machine init on Linux
        ├── postman.sh             # Postman — cask / snap
        ├── obsidian.sh            # Obsidian — cask / flatpak
        ├── figma.sh               # Figma — cask / flatpak
        ├── openvpn.sh             # OpenVPN — cask / apt
        └── db/
            ├── postgres.sh        # PostgreSQL — brew / apt + systemctl
            ├── mysql.sh           # MySQL — brew / apt + systemctl
            ├── mongodb.sh         # MongoDB 8.0 — brew tap / apt repo + systemctl
            └── redis.sh           # Redis — brew / apt + systemctl
```

---

## 9. Adding a New Package

1. Create `setup/packages/<name>.sh` (or `setup/packages/apps/<name>.sh` for
   GUI applications).
2. Follow the standard template:

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
           macos)  install_pkg "<brew-name>" ;;
           debian) install_pkg "<apt-name>"  ;;
           fedora) install_pkg "<dnf-name>"  ;;
           arch)   install_pkg "<pacman-name>" ;;
       esac
       log_success "<Name> installed."
   }

   export -f is_<name>_installed
   export -f install_<name>

   if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
       install_<name>
   fi
   ```

3. Register the package in `main.sh`:

   ```bash
   declare -A PACKAGES=(
       ...
       [<name>]="packages/<name>.sh"
   )
   declare -A PACKAGE_DESCS=(
       ...
       [<name>]="Short description"
   )
   PACKAGE_KEYS=( ... <name> )
   ```

4. If the tool is macOS-only, guard with `is_macos` and `log_warn` + `return 0`
   on other platforms rather than creating a separate script.
