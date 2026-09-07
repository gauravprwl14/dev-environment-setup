# Findings: Java & Android/Android Studio package scripts

Audit requested to check whether `setup/packages/java.sh` and an
Android/Android Studio installer exist, are registered in `main.sh`, and
match how these tools are actually used/installed on a real machine
(cross-checked against `~/.zshrc`).

---

## 1. Android Studio — script existed but was broken and disconnected

**Finding:** `setup/sdk/android_studio.sh` existed but:

- Lived in `setup/sdk/`, a directory outside repo convention (`packages/`,
  `packages/apps/`) and referenced nowhere else in the repo.
- Was **not registered** in `main.sh`'s `PACKAGES` array — `./main.sh
  --install android-studio` failed with "Unknown package."
- Was macOS-only with no `detect_os` branching (hardcoded `hdiutil` DMG
  mount, `/Applications` copy) — would not run on Linux at all.
- Hardcoded a specific, already-stale Android Studio version
  (`2024.1.1.12`) and a Mac-ARM-only download URL, rather than resolving
  the latest release.
- Used raw `echo` instead of `lib/logger.sh` helpers (`log_info`,
  `log_success`, etc.), against the logging convention.
- Had no `is_android_studio_installed` idempotency check — re-running it
  would re-download and re-copy the app every time.
- Sourced the legacy `utils/update_zshrc.sh` instead of the current
  `utils/update_shell_rc.sh`.
- Also drove `sdkmanager`/`avdmanager` to provision SDK platform-tools,
  emulator, a pinned system image, and create an AVD — none of which is
  installed on this machine (`~/Library/Android/sdk` does not exist).

**Fix applied:**

- Added `setup/packages/apps/android-studio.sh` — conforming to repo
  conventions: sources `detect_os.sh` / `pkg.sh` / `logger.sh`, has an
  `is_android_studio_installed` idempotency check, and branches per OS:
  - macOS: `install_cask android-studio` (Homebrew Cask)
  - Debian/Fedora: Flatpak (`flathub com.google.AndroidStudio`), falling
    back to `snap install android-studio --classic` if Flatpak isn't
    available
  - Arch: AUR via `yay`/`paru` (package name `android-studio`)
- Registered it in `main.sh`'s `PACKAGES`, `PACKAGE_DESCS`, and
  `PACKAGE_KEYS` under the key `android-studio`.
- Added a `DEPRECATED` header comment to the old
  `setup/sdk/android_studio.sh` pointing here, rather than deleting it
  outright (it's a tracked/committed file — deletion left as a decision
  for you once the new script is verified on a real machine).

**Scope note — not fixed, intentionally:** the new script installs the
Android Studio **IDE only**. It does not provision the Android SDK,
platform-tools, emulator images, or an AVD (what the old script's
`setupSDK`/`setupAVD` attempted). Android Studio's bundled SDK Manager can
do this interactively on first launch; a proper unattended equivalent
would be a separate `packages/android-sdk.sh` driving `sdkmanager` with an
explicit platform/build-tools/system-image version list, plus `ANDROID_HOME`
registration via `add_to_shell_rc`. Not built here — flagging as a
follow-up if headless SDK provisioning is actually needed.

**Known limitation:** the Debian/Fedora Flatpak app ID
(`com.google.AndroidStudio`) and the snap package name (`android-studio`)
are unrelated strings — this script special-cases both explicitly rather
than reusing `lib/pkg.sh`'s generic `install_cask` (which assumes one name
works for both flatpak and snap, and doesn't pass `--classic`). This is a
real gap in `install_cask` for any package whose flatpak/snap names or
confinement requirements diverge — worth revisiting `lib/pkg.sh` if more
packages hit the same issue.

---

## 2. Java — script exists and is registered, but doesn't match this machine's real setup

**Finding:** `setup/packages/java.sh` exists, is registered in `main.sh`,
and works as designed: it installs SDKMAN (if missing), then installs Java
via `sdk install java <version>` (default `21.0.2-tem`, Eclipse Temurin
21 LTS), then registers `JAVA_HOME` in the shell rc.

However, on this machine, Java was **not** installed this way:

- `~/.zshrc` sets `JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/...`
  — a Zulu 17 JDK installed via a system `.pkg` installer, not SDKMAN.
- `~/.sdkman` does not exist on this machine at all.

Running `java.sh` today would install SDKMAN and a second, SDKMAN-managed
Temurin 21 alongside the existing Zulu 17 install, rather than aligning
with it — two different Java installs, two different vendors, two
different versions, coexisting.

**Fix:** not applied — this needs a decision, not a guess. Two ways to
resolve it, and behavior differs meaningfully:

1. **Keep SDKMAN as the repo's standard** (current script behavior).
   Treat the existing Zulu 17 pkg install as a manual, one-off setup that
   predates the tool, and let `java.sh` continue managing Java via SDKMAN
   going forward (call `install_java 17.0.9-tem` if Zulu-flavored Temurin
   parity matters, or accept Temurin as the vendor).
2. **Match the actual machine setup** — rewrite `java.sh` to install a
   specific vendor/version JDK directly (e.g.
   `brew install --cask zulu17` on macOS, matching per-OS system package
   equivalents on Linux) instead of going through SDKMAN.

No code change made pending that choice — `java.sh` is otherwise sound
and already accepts a version argument (`install_java 17.0.9-tem`) if
option 1 is chosen as-is.
