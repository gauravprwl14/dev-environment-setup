# Getting Started

A cross-platform CLI for automating developer environment setup on **macOS** and **Linux** (Ubuntu/Debian, Fedora/RHEL, Arch/Manjaro). Install SDKs, CLI tools, databases, and GUI applications through an interactive menu or non-interactive flags — all scripts are idempotent and safe to re-run.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Usage](#usage)
4. [First-Time Setup Walkthrough](#first-time-setup-walkthrough)
5. [Platform-Specific Notes](#platform-specific-notes)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| **Bash 4+** | macOS ships with Bash 3 — see note below |
| **git** | Required to clone the repository |
| **curl** | Required by several package installers |
| **sudo access** | Required on all Linux platforms; not required for Homebrew on macOS |

### macOS and Bash 3

macOS bundles Bash 3.2 due to licensing restrictions. The scripts use Bash 4+ features (associative arrays, `[[ ]]` with `=~`, etc.), so you must either:

**Option A — Install Bash 4+ via Homebrew (recommended):**

```bash
brew install bash
```

Then invoke the script explicitly with the updated binary:

```bash
/opt/homebrew/bin/bash setup/main.sh        # Apple Silicon
/usr/local/bin/bash setup/main.sh           # Intel Mac
```

**Option B — Run with the system `/bin/bash` shebang override:**

macOS's `/bin/bash` is Bash 3. If Homebrew is not yet installed, bootstrap it first (the script does this automatically on first run), then use Option A going forward.

> **Tip:** You can check your active Bash version with `bash --version`.

---

## Installation

Clone the repository to a location of your choice:

```bash
git clone https://github.com/your-org/dev-environment-setup.git
cd dev-environment-setup
```

Make the entry point executable:

```bash
chmod +x setup/main.sh
```

> The repository does not need to be installed system-wide. You can run `setup/main.sh` from any location as long as the repository directory structure is intact.

---

## Usage

All commands are run from the repository root.

### Interactive menu (default)

Running the script with no arguments launches an interactive selection menu:

```bash
./setup/main.sh
```

If [`fzf`](https://github.com/junegunn/fzf) is installed, a fuzzy multi-select menu is shown. Use `TAB` to toggle items and `ENTER` to confirm. Without `fzf`, a numbered list is displayed and you enter package names or numbers separated by commas.

### List available packages

Print all available package names and descriptions, then exit:

```bash
./setup/main.sh --list
```

Example output:

```
  NAME              DESCRIPTION
  ────────────────  ──────────────────────────────────────────
  node              Node.js via nvm (cross-platform)
  yarn              Yarn package manager
  docker            Docker (Desktop on macOS, Engine on Linux)
  java              Java JDK via SDKMAN
  flutter           Flutter SDK
  dart              Dart SDK
  fvm               Flutter Version Manager
  watchman          Watchman file watcher (Meta)
  miniconda         Miniconda (Python)
  cocoapods         CocoaPods (macOS only)
  postgres          PostgreSQL 17
  mysql             MySQL
  mongodb           MongoDB 8.0
  redis             Redis
  cursor            Cursor IDE
  podman            Podman container engine
  postman           Postman API client
  obsidian          Obsidian note-taking app
  figma             Figma design tool
  openvpn           OpenVPN
```

### Install specific packages

Pass a comma-separated list of package names to `--install`:

```bash
./setup/main.sh --install node,docker
./setup/main.sh --install node,yarn,postgres,redis
./setup/main.sh --install java,flutter,dart,fvm
```

### Install everything

Install all registered packages in one shot:

```bash
./setup/main.sh --all
```

### Dry run (preview only)

Combine `--dry-run` with any install mode to preview what would happen without executing anything:

```bash
./setup/main.sh --dry-run --all
./setup/main.sh --dry-run --install node,docker,postgres
```

Dry-run output is prefixed with `[dry-run]` so it is easy to distinguish from live output.

### Help

```bash
./setup/main.sh --help
```

---

## First-Time Setup Walkthrough

Follow these steps when setting up a brand-new machine.

### Step 1 — Run the interactive menu and pick your tools

```bash
./setup/main.sh
```

The script will:

1. Detect your OS and CPU architecture automatically.
2. Run the platform bootstrap (installs Homebrew on macOS, or updates `apt`/`dnf`/`pacman` on Linux and adds Flatpak + Flathub).
3. Install each package you selected, in order.

If you already know exactly which packages you want, skip the menu:

```bash
./setup/main.sh --install node,yarn,docker,postgres
```

### Step 2 — Reload your shell

Package scripts that modify `PATH` (e.g. `nvm`, SDKMAN, Miniconda) write their initialisation lines to your shell rc file (`~/.zshrc` or `~/.bashrc`). Reload the file so the changes take effect in your current session:

```bash
# zsh (default on macOS)
source ~/.zshrc

# bash
source ~/.bashrc
```

Alternatively, open a new terminal window — the rc file is sourced automatically on startup.

### Step 3 — Verify your installs

Spot-check the tools you installed:

```bash
node --version          # e.g. v22.x.x
npm --version
docker --version
java --version
flutter --version
psql --version          # PostgreSQL client
redis-cli --version
```

If any command is not found, see [Troubleshooting](#troubleshooting) below.

---

## Platform-Specific Notes

### macOS

- **Homebrew is installed automatically** during the platform bootstrap step. You do not need to install it separately.
- **Apple Silicon (arm64):** Homebrew is installed to `/opt/homebrew/bin`. This path is added to your shell rc file automatically.
- **Intel (x86_64):** Homebrew is installed to `/usr/local/bin`.
- **Xcode Command Line Tools:** Some packages (e.g. CocoaPods, certain compilers) require the Xcode CLT. Install them with:

  ```bash
  xcode-select --install
  ```

- **CocoaPods** is macOS-only. It will be skipped silently on Linux.
- GUI applications are installed via **Homebrew Cask** (e.g. Docker Desktop, Cursor, Obsidian, Figma, Postman).

### Ubuntu / Debian (and Linux Mint)

- **`sudo` access is required.** The bootstrap step runs `apt-get update` and installs essential build tools (`curl`, `git`, `build-essential`, `gnupg`, `ca-certificates`).
- **Flatpak** and the **Flathub** remote are added automatically during bootstrap. Some GUI apps are distributed as Flatpaks on Linux.
- **snapd** is installed during bootstrap for packages that require Snap.
- Certain packages (e.g. Docker Engine, MongoDB) add their own `apt` repositories and GPG keys — this is handled transparently by the package scripts.

### Fedora / RHEL / CentOS / Rocky Linux

- **`sudo` access is required.** The bootstrap step uses `dnf` to install essential tools (`curl`, `git`, `gcc`, `gcc-c++`, `make`, `wget`).
- **RPM Fusion** (both `free` and `nonfree` repos) is enabled automatically during bootstrap. This is required for several packages.
- **Flatpak** and **Flathub** are added automatically during bootstrap.
- Package installation uses `dnf` as the primary package manager.

### Arch Linux / Manjaro

- **`sudo` access is required.** The bootstrap step refreshes the `pacman` package database (`pacman -Sy`).
- **AUR packages:** For packages not available in the official Arch repos, it is strongly recommended to have [`yay`](https://github.com/Jguer/yay) or [`paru`](https://github.com/morganamilo/paru) installed before running the setup scripts. Install one of them first:

  ```bash
  # yay
  sudo pacman -S --needed git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay && makepkg -si

  # paru (alternative)
  sudo pacman -S --needed git base-devel
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  cd /tmp/paru && makepkg -si
  ```

- Flatpak and Flathub are used for GUI apps not available in the official repos or AUR.

---

## Troubleshooting

### 1. Command not found after install

**Symptom:** Running `node`, `java`, `flutter`, etc. returns `command not found` immediately after installation completes.

**Cause:** The package installer wrote `PATH` or initialisation lines to `~/.zshrc` / `~/.bashrc`, but the current shell session has not picked them up yet.

**Fix:** Reload your shell rc file:

```bash
source ~/.zshrc    # zsh
source ~/.bashrc   # bash
```

Or open a new terminal window.

---

### 2. Permission denied

**Symptom:** The script exits with a `Permission denied` error or `sudo: command not found`.

**Cause:** Your user account does not have `sudo` privileges, or `sudo` is not installed.

**Fix:**

```bash
# Check if sudo is available
which sudo

# Add your user to the sudoers group (run as root or an existing sudo user)
# Ubuntu/Debian:
usermod -aG sudo $USER

# Fedora/RHEL:
usermod -aG wheel $USER
```

Log out and back in for the group change to take effect.

> On macOS, Homebrew does not require `sudo`. If you see a permission error on macOS it is likely a file ownership issue — run `brew doctor` for guidance.

---

### 3. Homebrew not found on macOS

**Symptom:** After the script runs, `brew` is still not found on `PATH`.

**Cause:** The Homebrew bin directory was not picked up by the current shell session, or the installation failed silently.

**Fix:**

1. Reload your shell rc file: `source ~/.zshrc`
2. Check that the Homebrew path is present in `~/.zshrc`:

   ```bash
   grep HOMEBREW ~/.zshrc
   ```

3. If the line is missing, re-run the setup — the platform bootstrap is idempotent and will add the path again:

   ```bash
   ./setup/main.sh
   ```

4. For Apple Silicon, confirm the binary exists at `/opt/homebrew/bin/brew`. For Intel, check `/usr/local/bin/brew`.

---

### 4. snap or flatpak not available on Linux

**Symptom:** A package script fails because `snap` or `flatpak` is not found.

**Cause:** The platform bootstrap has not been run yet, or it was skipped. `snapd` and `flatpak` are installed during the bootstrap step, which runs automatically at the start of every `./setup/main.sh` invocation.

**Fix:** Run the setup script and let the bootstrap step complete fully:

```bash
./setup/main.sh
```

If you interrupted a previous run before the bootstrap finished, simply re-run — it is safe to do so. On Ubuntu/Debian, you can also bootstrap manually:

```bash
sudo apt-get update
sudo apt-get install -y flatpak snapd
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

---

### 5. Script fails partway through

**Symptom:** The script exits with an error mid-installation (e.g. a network timeout, a missing dependency, or an unexpected package manager error).

**Cause:** Various transient or environment-specific failures. The script runs with `set -euo pipefail`, so any non-zero exit from a sub-command causes an immediate stop.

**Fix:** Simply re-run the same command. Every package script checks whether the tool is already installed before attempting to install it — re-running is completely safe and will skip anything already in place:

```bash
# Re-run the exact same command you used before
./setup/main.sh --install node,docker,postgres

# Or use --dry-run first to confirm what would be attempted
./setup/main.sh --dry-run --install node,docker,postgres
```

If the same step keeps failing, check the error message for the specific package and consult that package's official documentation for platform-specific prerequisites.
