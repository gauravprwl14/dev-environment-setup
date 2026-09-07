# CLAUDE.md — dev-environment-setup

This file gives Claude Code context about the project conventions, architecture, and rules to follow when working in this repository.

---

## Project Overview

A cross-platform CLI tool that automates developer environment setup on **macOS** and **Linux** (Ubuntu/Debian, Fedora, Arch). It installs SDKs, CLI tools, databases, and GUI applications via an interactive menu or command-line flags.

---

## Repository Structure

```
setup/
├── main.sh                    # CLI entry point
├── lib/
│   ├── detect_os.sh           # OS detection (macos | debian | fedora | arch)
│   ├── logger.sh              # Colored output helpers: log_info, log_success, log_warn, log_error
│   └── pkg.sh                 # Package manager abstraction: install_pkg, install_cask, add_service
├── utils/
│   ├── update_shell_rc.sh     # Cross-platform shell rc writer (.zshrc / .bashrc)
│   └── change_permission.sh
├── platform/
│   ├── macos/
│   │   ├── homebrew.sh
│   │   ├── xcode.sh
│   │   └── mas.sh
│   └── linux/
│       ├── apt.sh
│       ├── dnf.sh
│       └── snap.sh
└── packages/                  # Cross-platform package scripts
    ├── node.sh
    ├── docker.sh
    ├── yarn.sh
    ├── java.sh
    ├── flutter.sh
    └── apps/
        ├── cursor.sh
        ├── podman.sh
        └── db/
            ├── postgres.sh
            └── mysql.sh
plan/
└── cross-platform-cli.md      # Full implementation plan
CLAUDE.md                      # This file
README.md
```

---

## Core Conventions

### Shell Scripts

- All scripts use `#!/bin/bash` shebang
- Every script checks `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` before calling functions directly, so scripts can be safely sourced or executed
- Functions are exported with `export -f <function_name>` when needed by child scripts
- Each package script is self-contained and idempotent (safe to run multiple times)

### Cross-Platform Rules

- **Never call `brew` directly** in package scripts — always go through `lib/pkg.sh` helpers
- **Never hardcode `/opt/homebrew/`** or any macOS-specific path in package scripts
- **Never use `open /Applications/`** — use platform-specific launch logic in `lib/pkg.sh`
- **Never use `sed -i ''`** directly — use the `portable_sed_inplace` helper from `utils/update_shell_rc.sh`
- **Never hardcode `.zshrc`** — use `get_rc_file` from `utils/update_shell_rc.sh`
- Platform-specific code belongs in `platform/macos/` or `platform/linux/`, not in `packages/`

### Naming

- Functions: `snake_case` (e.g., `install_docker`, `is_node_installed`)
- Files: `snake_case.sh`
- Constants/exported vars: `UPPER_SNAKE_CASE`

### Logging

Always use the helpers from `lib/logger.sh` — never raw `echo` in package scripts:
```bash
log_info  "Installing Docker..."
log_success "Docker installed."
log_warn  "Docker already installed, skipping."
log_error "Failed to install Docker."
```

### OS Detection

Always source `lib/detect_os.sh` and use `detect_os` before any platform-specific logic:
```bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/detect_os.sh"

case "$(detect_os)" in
    macos)  ... ;;
    debian) ... ;;
    fedora) ... ;;
    arch)   ... ;;
esac
```

### Package Manager Abstraction

Source `lib/pkg.sh` and use:
- `install_pkg <name>` — CLI tools (brew / apt / dnf / pacman)
- `install_cask <name>` — GUI apps (brew --cask / flatpak / snap / deb)
- `add_service <name>` — Start + enable service (brew services / systemctl)

---

## CLI Interface (`main.sh`)

```
Usage: ./main.sh [OPTIONS]

Options:
  (no args)           Interactive menu (checkbox-based)
  --all               Install all packages
  --install <list>    Comma-separated list of packages (e.g. node,docker,postgres)
  --list              List all available packages
  --dry-run           Preview what would be installed without executing
  --help, -h          Show help
```

---

## Installation Policy

- **All installs go through a package script.** Never install anything (CLI tool, SDK, GUI app, database) by running `brew`, `apt`, `dnf`, `pacman`, `flatpak`, `snap`, etc. directly in a session. If a package script doesn't exist yet for what's being requested, create it first, then install via `./main.sh --install <name>`.
- If the user asks to "install X" and no script for X exists under `setup/packages/`, the correct sequence is: write the script → test and verify it (see below) → register it in `main.sh` → then run the install through `main.sh`. Do not shortcut this by calling the package manager ad hoc, even "just this once."

---

## Adding a New Package

1. Create `setup/packages/<name>.sh` (or `setup/packages/apps/<name>.sh` for GUI apps)
2. Source `lib/detect_os.sh` and `lib/pkg.sh` at the top
3. Implement `is_<name>_installed()` and `install_<name>()`
4. Use `case "$(detect_os)"` for any platform-specific logic
5. Guard direct execution with the `BASH_SOURCE` check
6. Register the package in `main.sh`'s `PACKAGES`, `PACKAGE_DESCS`, and `PACKAGE_KEYS`
7. Test and verify the script (see below) before treating it as done

---

## Script Testing & Verification Gate

A package script is not considered finished/executable until all of these pass:

1. **Syntax check** — `bash -n setup/packages/<path>/<name>.sh`
2. **Registry wiring** — `./main.sh --list` shows the new package, and `./main.sh --dry-run --install <name>` runs cleanly
3. **Real install** — `./main.sh --install <name>` completes without error, and `is_<name>_installed` returns success (0) afterward
4. **Idempotency** — running the install a second time detects the already-installed state and skips cleanly, rather than re-installing or erroring
5. **Install functions must fail loudly** — `install_<name>()` must check the exit status of the underlying `install_pkg`/`install_cask`/`flatpak install` call and return non-zero on failure. Never call `log_success` unconditionally after an install step; only log success once `is_<name>_installed` confirms it.

Only after all of the above pass should the script be registered for regular use or reported back to the user as done.

---

## What NOT to Do

- Do not add packages to `main.sh` by hardcoding script calls — register them in the `PACKAGES` array instead
- Do not create platform-specific forks of a whole script — keep one script, branch inside it with `detect_os`
- Do not commit with `--no-verify`
- Do not use `sudo` without checking if it is needed (macOS Homebrew does not require sudo)
- Do not write to `.zshrc` without using `update_shell_rc.sh`
