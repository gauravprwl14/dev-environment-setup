# Contributing to dev-environment-setup

Thank you for your interest in contributing. This project is a cross-platform developer environment CLI, and contributions of all kinds are welcome — whether you are fixing a bug, adding support for a new tool, improving platform compatibility, or clarifying the docs. This guide explains everything you need to get started.

---

## Ways to Contribute

| Type | Examples |
|---|---|
| **Bug reports** | A script fails on Fedora; `detect_os` returns `unknown`; a service does not start |
| **New packages** | Add Redis support for Arch; add a Rust toolchain installer |
| **Platform improvements** | Improve apt bootstrap; add ARM support for a package |
| **Documentation** | Fix inaccurate steps; add examples; expand platform notes |

For significant changes (new packages, architecture changes), open an issue first to align on the approach before investing time in an implementation.

---

## Development Setup

```bash
# Clone the repository
git clone https://github.com/your-org/dev-environment-setup.git
cd dev-environment-setup

# No build step required — all scripts are plain Bash.
# Verify the entry point is executable:
chmod +x setup/main.sh
./setup/main.sh --help
```

**Branch naming convention:**

| Prefix | Use for |
|---|---|
| `feature/` | New packages or capabilities |
| `fix/` | Bug fixes |
| `chore/` | Maintenance, dependency updates, refactoring |

Examples: `feature/add-rust-installer`, `fix/docker-usermod-no-sudo`, `chore/update-postgres-version`

---

## Branch and PR Workflow

1. **Create a branch from `main`.**

   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/add-redis-arch-support
   ```

2. **Make your changes**, following the code conventions below.

3. **Test on the target platform(s).** See the [Testing](#testing) section for commands.

4. **Open a pull request** against `main`. Your PR description should explain:
   - What the change does
   - Why it is needed
   - Which platform(s) you tested on
   - Any edge cases or limitations

Keep PRs focused. A PR that adds one package is easier to review than one that adds five.

---

## Adding a New Package

For a detailed walkthrough with a full annotated example, see [guides/adding-a-package.md](guides/adding-a-package.md). The steps below summarise the process.

### 1. Create the package script

- CLI tools go in `setup/packages/<name>.sh`
- GUI applications go in `setup/packages/apps/<name>.sh`
- Database servers go in `setup/packages/apps/db/<name>.sh`

Use `setup/packages/docker.sh` as a reference. Every package script follows this structure:

```bash
#!/bin/bash

# packages/<name>.sh — Brief description of what this installs.

source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pkg.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logger.sh"


# is_<name>_installed
# Returns 0 if already installed, 1 otherwise.
is_<name>_installed() {
    if command -v <binary> &> /dev/null; then
        log_info "<Name> is installed."
        return 0
    else
        log_info "<Name> is not installed."
        return 1
    fi
}


# install_<name>
# Installs <name> using the correct method for the current OS.
install_<name>() {
    if is_<name>_installed; then
        log_success "<Name> is already installed. Skipping."
        return 0
    fi

    local os
    os="$(detect_os)"

    log_step "Installing <Name> (OS: ${os})"

    case "${os}" in
        macos)
            install_pkg <brew-name>
            ;;
        debian)
            install_pkg <apt-name>
            ;;
        fedora)
            install_pkg <dnf-name>
            ;;
        arch)
            install_pkg <pacman-name>
            ;;
        *)
            log_error "install_<name>: unsupported OS '${os}'"
            return 1
            ;;
    esac

    log_success "<Name> installed."
}


export -f is_<name>_installed
export -f install_<name>


# Run install_<name> when this script is executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_<name>
fi
```

### 2. Register the package in `main.sh`

Open `setup/main.sh` and add an entry to both the `PACKAGES` and `PACKAGE_DESCS` arrays:

```bash
PACKAGES=(
    ...
    "<name>"
)

PACKAGE_DESCS=(
    ...
    "<name>:<one-line description>"
)
```

The key in `PACKAGES` must match the script filename (without `.sh`). The CLI uses these arrays to build the interactive menu and to resolve `--install` arguments.

### 3. Test with a dry-run

```bash
./setup/main.sh --dry-run --install <name>
# or test everything at once:
./setup/main.sh --dry-run --all
```

Confirm your package appears in the output without errors before running a live install.

---

## Code Conventions

These conventions are enforced across the codebase. PRs that do not follow them will be asked to revise.

### Always use `lib/pkg.sh` abstractions — never raw package manager calls

```bash
# Correct
install_pkg git
install_cask cursor
add_service postgresql

# Wrong — never call brew, apt-get, dnf, or pacman directly in a package script
brew install git
sudo apt-get install -y git
```

The `lib/pkg.sh` helpers route each call to the correct package manager for the detected OS. Calling a package manager directly breaks cross-platform support.

### Always use `lib/logger.sh` — never raw `echo`

```bash
# Correct
log_info    "Downloading archive..."
log_success "Installation complete."
log_warn    "Already installed, skipping."
log_error   "Unsupported OS."

# Wrong
echo "Downloading archive..."
```

The logger adds colour, prefixes (`[INFO]`, `[OK]`, `[WARN]`, `[ERROR]`), and strips ANSI codes automatically when output is piped to a file.

### Every script must be idempotent

Running a script twice must produce the same result as running it once. Always check whether a tool is already installed before attempting to install it, and return early with `log_success` if it is. The `is_<name>_installed` function pattern enforces this.

### Use `detect_os` for all platform branching

```bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/detect_os.sh"

case "$(detect_os)" in
    macos)  ... ;;
    debian) ... ;;
    fedora) ... ;;
    arch)   ... ;;
    *)
        log_error "Unsupported OS: $(detect_os)"
        return 1
        ;;
esac
```

`detect_os` returns one of: `macos`, `debian`, `fedora`, `arch`, or `unknown`. Do not hardcode OS strings or paths outside of this pattern.

### Naming conventions

| Thing | Convention | Example |
|---|---|---|
| Functions | `snake_case` | `install_docker`, `is_node_installed` |
| Files | `snake_case.sh` | `detect_os.sh`, `update_shell_rc.sh` |
| Constants / exported vars | `UPPER_SNAKE_CASE` | `NVM_INSTALL_URL`, `NVM_SH` |

### Additional rules

- All scripts use `#!/bin/bash` as the shebang.
- Guard direct execution with `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` so scripts can be safely sourced or executed.
- Export public functions with `export -f <function_name>`.
- Do not hardcode paths like `/opt/homebrew/` or shell files like `.zshrc`. Use `update_shell_rc.sh` helpers (`get_rc_file`, `add_to_shell_rc`) to write shell configuration portably.
- Do not use `sudo` on macOS unless absolutely necessary — Homebrew does not require it.
- Do not use `sed -i ''` directly — use `portable_sed_inplace` from `utils/update_shell_rc.sh`.

---

## Testing

### macOS

Run the full dry-run to verify the interactive menu and all package registrations:

```bash
./setup/main.sh --dry-run --all
```

Run your specific package script directly to exercise it in isolation:

```bash
bash setup/packages/<name>.sh
```

### Linux (Docker)

Test on Debian/Ubuntu:

```bash
docker run --rm -it ubuntu:22.04 bash
# Inside the container:
apt-get update && apt-get install -y git curl
git clone https://github.com/your-org/dev-environment-setup.git
cd dev-environment-setup/setup
bash packages/<name>.sh
```

Test on Fedora:

```bash
docker run --rm -it fedora:latest bash
# Inside the container:
dnf install -y git curl
git clone https://github.com/your-org/dev-environment-setup.git
cd dev-environment-setup/setup
bash packages/<name>.sh
```

### Standalone script test

Every package script must be runnable on its own:

```bash
bash setup/packages/docker.sh
bash setup/packages/node.sh
bash setup/packages/apps/db/postgres.sh
```

If a script fails when run directly, that is a bug — fix it before opening a PR.

### What to verify

- The package installs cleanly on a fresh system (or Docker container).
- The script exits cleanly with `log_success` if the package is already present (idempotency).
- The `--dry-run` flag shows the package in the preview list without error.
- No raw `echo`, `brew`, `apt-get`, `dnf`, or `pacman` calls appear in the diff.

---

## Commit Message Format

This project uses [Conventional Commits](https://www.conventionalcommits.org/). Every commit message must follow the format:

```
<type>(<scope>): <short description>
```

**Types:**

| Type | Use for |
|---|---|
| `feat` | A new package, feature, or capability |
| `fix` | A bug fix |
| `chore` | Maintenance, version bumps, refactoring with no behaviour change |
| `docs` | Documentation only |
| `test` | Adding or updating tests |
| `refactor` | Code restructuring that does not change behaviour |

**Examples:**

```
feat(packages): add redis support for Fedora
fix(docker): handle usermod on systems without sudo
chore(deps): update PostgreSQL version to 17
docs(contributing): add Linux Docker testing instructions
refactor(node): extract nvm version check into is_nvm_installed
```

Keep the subject line under 72 characters. Use the commit body for additional context when the change is non-obvious.

---

## Code of Conduct

This project is a professional open-source tool. All contributors are expected to engage respectfully and constructively. Criticism of code is welcome; personal criticism is not. Contributions that are dismissive, abusive, or otherwise unprofessional will not be accepted, and the contributor may be blocked from further participation at the maintainers' discretion.

If you experience or witness conduct that falls short of this standard, please reach out to the maintainers directly.
