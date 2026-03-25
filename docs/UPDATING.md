# Updating Skills

This document covers how to pull the latest skills, scripts, and dependencies after the `dev-environment-setup` repo has been updated on GitHub.

---

## 1. Standard Update Flow

Three steps cover all update types. Run only the steps that apply to what changed.

```bash
# Step 1 — Pull latest from GitHub
cd ~/dev-environment-setup
git pull

# Step 2 — Re-install skills into your project
cd ~/my-content-project      # ← your Claude Code project directory
npx skills install ~/dev-environment-setup/skills --yes

# Done for code/instruction changes. For dependency changes:

# Step 3a — Update Python packages (only if requirements.txt changed)
pip install -r ~/dev-environment-setup/requirements.txt

# Step 3b — Update Node packages (only if hashnode scripts changed)
cd ~/dev-environment-setup/skills/hashnode/scripts && npm install
```

Steps 3a and 3b are only needed when the corresponding dependency files changed. Check the git log (see section 4) to confirm before running them.

---

## 2. One-Command Update (Recommended)

The `install.sh` script handles the git pull, skill reinstall, and dependency refresh in a single command:

```bash
# From your project directory:
cd ~/my-content-project
bash ~/dev-environment-setup/skills/install.sh
```

If you are working in the `content-creator` repo, use its wrapper instead:

```bash
cd ~/content-creator
./setup.sh
```

The installer is idempotent — it is safe to run multiple times. It skips steps that are already up-to-date (for example, `node_modules` already present). When in doubt, just run `install.sh` rather than the manual steps.

---

## 3. Update Scenarios

### Scenario A — New skill added

A new `SKILL.md` was added to the skills repo. Re-running the install picks it up automatically.

```bash
npx skills install ~/dev-environment-setup/skills --yes
```

### Scenario B — Existing skill updated

A `SKILL.md` was changed (better instructions, bug fix). Re-running the install overwrites the old version in your project.

```bash
npx skills install ~/dev-environment-setup/skills --yes
```

### Scenario C — Script updated (yt-transcript, image-generator, hashnode)

A Python or Node.js script was changed. Re-running install copies the updated scripts.

```bash
npx skills install ~/dev-environment-setup/skills --yes
```

### Scenario D — New Python package dependency

A new package was added to `requirements.txt`. After pulling, reinstall Python packages.

```bash
pip install -r ~/dev-environment-setup/requirements.txt
```

### Scenario E — New Node.js dependency

A new package was added to `hashnode/scripts/package.json`. After pulling, run npm install in that directory.

```bash
cd ~/dev-environment-setup/skills/hashnode/scripts && npm install
```

---

## 4. Checking Your Current Version

Before or after updating, use these commands to see where you stand.

```bash
# See current local state (last 5 commits)
cd ~/dev-environment-setup && git log --oneline -5

# See what is on GitHub
git fetch origin && git log --oneline origin/main -5

# Check if your local branch is behind remote
git status
```

To see exactly what commits you are missing before pulling:

```bash
cd ~/dev-environment-setup
git fetch origin
git log HEAD..origin/main --oneline
```

This also helps you identify whether a breaking change is incoming (check the CHANGELOG if present, or read the commit messages).

To count how many skills are currently installed in your project:

```bash
ls .agents/skills/ | wc -l
```

---

## 5. After Updating

### Restart Claude Code

Skills are loaded at Claude Code startup. After reinstalling, you must restart Claude Code for the changes to take effect:

```bash
claude .   # reopen Claude Code in your project directory
```

Simply re-running commands in an open Claude Code session will not pick up updated skills — a full restart is required.

### What does NOT change on update

The installer never touches the following. Your personal configuration and output files are always preserved:

- `~/.config/content-pipeline/.env` — API keys and path overrides. The installer only adds missing variables; it never overwrites existing values.
- Output files in `$CONTENT_PIPELINE_OUTPUT/` — untouched.
- Your Obsidian vault — untouched.

---

## 6. Pinning a Version

If you need to stay on a specific version (for stability or reproducibility), check out a tag or commit hash before reinstalling.

```bash
cd ~/dev-environment-setup

# Pin to a release tag
git checkout v1.2.0

# Or pin to a specific commit
git checkout abc1234
```

Then reinstall skills from that pinned version:

```bash
cd ~/my-project
npx skills install ~/dev-environment-setup/skills --yes
```

To return to the latest version later:

```bash
cd ~/dev-environment-setup
git checkout main
git pull
```

---

## 7. Troubleshooting

### Skills not appearing or old version still active

```bash
# Re-run the install
npx skills install ~/dev-environment-setup/skills --yes

# Restart Claude Code
claude .
```

### Script errors after update (Python or Node.js)

```bash
# Reinstall Python dependencies
pip install -r ~/dev-environment-setup/requirements.txt

# Reinstall Node dependencies for hashnode scripts
cd ~/dev-environment-setup/skills/hashnode/scripts && npm install
```

### Check everything at once

```bash
bash ~/dev-environment-setup/skills/install.sh --check
```

This runs the installer in check mode and reports what is out of date without making changes.
