# dev-environment-setup

Automated, cross-platform developer environment setup CLI for macOS and Linux.

![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue)
![Shell](https://img.shields.io/badge/shell-bash-89e051)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Overview

`dev-environment-setup` is a bash CLI that provisions a developer workstation from scratch. It installs SDKs, CLI tools, databases, and GUI applications through an interactive menu or command-line flags, and routes every installation through a platform abstraction layer so the same package scripts run on macOS (Homebrew), Ubuntu/Debian (apt), Fedora (dnf), and Arch Linux (pacman). It is aimed at developers who need to reproduce a consistent environment across machines or operating systems without maintaining separate setup scripts per platform.

---

## Table of Contents

- [Getting Started](getting-started.md)
- [Architecture](architecture.md)
- [Package Reference](packages.md)
- [Contributing / Adding a Package](contributing.md)
- **Guides**
  - [Adding a New Package](guides/adding-a-package.md)
  - [Platform Support](guides/platform-support.md)
- **Architecture Decision Records**
  - [ADR-0001: Cross-Platform Support](adr/0001-cross-platform-support.md)
  - [ADR-0002: Package Manager Abstraction](adr/0002-package-manager-abstraction.md)
  - [ADR-0003: Repository Strategy](adr/0003-repository-strategy.md)

---

## Quick Start

```bash
git clone https://github.com/your-org/dev-environment-setup.git
cd dev-environment-setup/setup
./main.sh
```

Run `./main.sh --help` for all available flags.

---

## Supported Platforms

| Platform | Architecture | Package Manager |
|---|---|---|
| macOS (Apple Silicon) | arm64 | Homebrew |
| macOS (Intel) | x86_64 | Homebrew |
| Ubuntu / Debian | x86_64, arm64 | apt |
| Fedora / RHEL | x86_64 | dnf |
| Arch Linux | x86_64 | pacman |

---

## Repository Layout

```
dev-environment-setup/
├── README.md                          # Project overview
├── CLAUDE.md                          # Conventions and rules for AI-assisted development
│
├── docs/                              # Documentation (you are here)
│   ├── index.md
│   ├── getting-started.md
│   ├── architecture.md
│   ├── packages.md
│   ├── contributing.md
│   ├── guides/
│   │   ├── adding-a-package.md
│   │   └── platform-support.md
│   └── adr/
│       ├── 0001-cross-platform-support.md
│       ├── 0002-package-manager-abstraction.md
│       └── 0003-repository-strategy.md
│
├── plan/
│   └── cross-platform-cli.md          # Implementation plan for cross-platform refactor
│
└── setup/                             # All executable scripts live here
    ├── main.sh                        # CLI entry point (interactive menu + flags)
    │
    ├── lib/                           # Shared libraries sourced by every package script
    │   ├── detect_os.sh               # Returns: macos | debian | fedora | arch | unknown
    │   ├── logger.sh                  # log_info / log_success / log_warn / log_error
    │   └── pkg.sh                     # install_pkg, install_cask, add_service abstraction
    │
    ├── utils/
    │   ├── update_shell_rc.sh         # Cross-platform rc writer (get_rc_file, add_to_shell_rc)
    │   ├── update_zshrc.sh            # Legacy zshrc helper (kept for backward compatibility)
    │   └── change_permission.sh
    │
    ├── platform/                      # Platform bootstrap (run once per machine)
    │   ├── macos/
    │   │   ├── homebrew.sh            # Install Homebrew
    │   │   ├── xcode.sh               # Install Xcode Command Line Tools
    │   │   └── mas.sh                 # Install Mac App Store CLI
    │   └── linux/
    │       ├── apt.sh                 # Bootstrap apt, curl, git, build-essential
    │       ├── dnf.sh                 # Bootstrap dnf, curl, git, make, gcc
    │       └── snap.sh                # install_snap_pkg / install_snap_classic helpers
    │
    ├── packages/                      # Cross-platform package scripts (primary)
    │   ├── node.sh                    # Node.js via nvm
    │   ├── yarn.sh                    # Yarn package manager
    │   ├── docker.sh                  # Docker (Desktop on macOS, Engine on Linux)
    │   ├── java.sh                    # JDK via SDKMAN
    │   ├── flutter.sh                 # Flutter SDK
    │   ├── dart.sh                    # Dart SDK
    │   ├── fvm.sh                     # Flutter Version Manager
    │   ├── miniconda.sh               # Miniconda / conda
    │   ├── cocoapods.sh               # CocoaPods (macOS-only, guarded)
    │   ├── watchman.sh                # Watchman file watcher
    │   └── apps/
    │       ├── cursor.sh              # Cursor IDE
    │       ├── figma.sh               # Figma
    │       ├── obsidian.sh            # Obsidian
    │       ├── openvpn.sh             # OpenVPN Connect
    │       ├── podman.sh              # Podman container engine
    │       ├── postman.sh             # Postman
    │       ├── redis.sh               # Redis
    │       └── db/
    │           ├── postgres.sh        # PostgreSQL
    │           ├── mysql.sh           # MySQL
    │           └── mongodb.sh         # MongoDB
    │
    └── sdk/                           # Legacy macOS-only scripts (pre-refactor)
        └── ...                        # Being migrated to packages/ — do not add new scripts here
```
