# YouTube Content Pipeline — Installation Guide

A step-by-step guide for installing the YouTube Content Pipeline skills into Claude Code or OpenClaw.

---

## Prerequisites

- **Python 3.8+** with `pip3`
- **Claude Code** OR **OpenClaw** installed
- (Optional) **Gemini API key** for image generation
- (Optional) **Obsidian vault** for note integration

---

## Method 1: Install All Skills via npx (Recommended)

The fastest way to get started. One command installs every skill in the pipeline.

### For Claude Code

```bash
npx skills i gp/dev-environment-setup
```

- When prompted, select **Claude Code**
- Skills install to `~/.claude/skills/`
- Immediately available as `/yt-transcript`, `/content-summarizer`, etc.

### For OpenClaw

```bash
npx skills i gp/dev-environment-setup
```

- When prompted, select **OpenClaw**
- Skills install to `~/.openclaw/workspace/skills/`

### Verify installation

```bash
# In Claude Code, type:
/yt-transcript
# Should respond: "YouTube Transcript loaded. Usage: ..."
```

---

## Method 2: Install a Single Skill

Install only what you need:

```bash
npx skills i gp/dev-environment-setup --skill yt-transcript
npx skills i gp/dev-environment-setup --skill content-summarizer
```

### Available skill names

| Skill name | Description |
|---|---|
| `yt-transcript` | Extract and format YouTube video transcripts |
| `content-summarizer` | Summarize transcripts into structured notes |
| `image-generator` | Generate images via Gemini API |
| `obsidian-note` | Create formatted notes in your Obsidian vault |
| `content-ideas` | Generate content ideas from transcripts |
| `social-posts` | Create social media posts from video content |
| `tweet-generator` | Generate tweet threads from transcripts |
| `youtube-pipeline` | Run the full end-to-end pipeline |
| `skill-scaffold` | Scaffold a new skill from a template |
| `obsidian-vault-guide` | Guide for setting up Obsidian vault integration |

---

## Method 3: Git Clone (Development / Full Control)

Best for contributors or anyone who wants to modify skills locally.

```bash
git clone https://github.com/gp/dev-environment-setup.git
cd dev-environment-setup
```

### Option A: Project-local (auto-discovered)

Skills are automatically discovered when you are inside the repo directory:

```bash
cd dev-environment-setup
claude  # skills are available
```

### Option B: Symlink for global access

Make skills available from any directory:

```bash
ln -s "$(pwd)/skills"/* ~/.claude/skills/
```

For OpenClaw:

```bash
ln -s "$(pwd)/skills"/* ~/.openclaw/workspace/skills/
```

---

## Method 4: Manual Copy

For users who want full control over what gets installed and where.

```bash
git clone https://github.com/gp/dev-environment-setup.git

# For Claude Code:
cp -r dev-environment-setup/skills/* ~/.claude/skills/

# For OpenClaw:
cp -r dev-environment-setup/skills/* ~/.openclaw/workspace/skills/
```

---

## Post-Install: Python Dependencies

Some skills require Python packages. Install them with:

```bash
# Required for /yt-transcript
pip3 install --user youtube-transcript-api>=1.2.4 yt-dlp

# Required for /image-generator
pip3 install --user google-genai>=1.0.0 Pillow>=10.0.0
```

---

## Post-Install: Configuration

### How Configuration Works

Skills load config with this priority (highest wins):

1. **Environment variables** — `export GEMINI_API_KEY=xxx`
2. **Shared pipeline config** — `~/.config/content-pipeline/.env`
3. **Per-skill config** — `~/.config/<skill-name>/.env`
4. **Built-in defaults** — for non-secret values only

### Step 1: Create the shared config file

```bash
mkdir -p ~/.config/content-pipeline && chmod 700 ~/.config/content-pipeline

cat > ~/.config/content-pipeline/.env << 'EOF'
# === YouTube Content Pipeline Configuration ===

# Required for /image-generator (get key at https://ai.dev)
GEMINI_API_KEY=

# Output directory for pipeline results (default: ~/content-pipeline/output)
CONTENT_PIPELINE_OUTPUT=~/content-pipeline/output

# Obsidian vault path for /obsidian-note (leave empty to skip)
OBSIDIAN_VAULT_PATH=
EOF

chmod 600 ~/.config/content-pipeline/.env
```

### Step 2: Add your API keys

Edit the file and fill in your values:

```bash
nano ~/.config/content-pipeline/.env
# OR
vim ~/.config/content-pipeline/.env
```

### Step 3: Verify config

```bash
source ~/.config/content-pipeline/.env && echo "GEMINI_API_KEY=${GEMINI_API_KEY:+set}" && echo "OUTPUT=$CONTENT_PIPELINE_OUTPUT"
```

### Configuration Reference Table

| Variable | Required For | Default | How to Get |
|---|---|---|---|
| `GEMINI_API_KEY` | `/image-generator` | — | https://ai.dev -> Create project -> API key |
| `CONTENT_PIPELINE_OUTPUT` | All skills | `~/content-pipeline/output` | Set any directory |
| `OBSIDIAN_VAULT_PATH` | `/obsidian-note` | — | Path to your Obsidian vault root |

### Per-Skill Config Override

You can override any key for a specific skill:

```bash
mkdir -p ~/.config/image-generator
echo 'GEMINI_API_KEY=different-key-for-images' > ~/.config/image-generator/.env
chmod 600 ~/.config/image-generator/.env
```

### Environment Variable Override

Highest priority — overrides all config files:

```bash
export GEMINI_API_KEY=my-key
/image-generator --prompt "test"  # uses the env var
```

---

## Verify Everything Works

### Quick smoke test

```bash
# 1. Check skills are discovered
/yt-transcript
# Expected: "YouTube Transcript loaded. Usage: ..."

# 2. Test transcript extraction
/yt-transcript https://www.youtube.com/watch?v=dQw4w9WgXcQ

# 3. Test image generator error handling (without API key)
/image-generator --prompt "test"
# Expected: diagnostic showing which config files were checked
```

### Full pipeline test

```bash
/youtube-pipeline https://www.youtube.com/watch?v=VIDEO_ID --only=transcript,summary
```

---

## Uninstall

### If installed via npx

```bash
# Remove all pipeline skills
rm -rf ~/.claude/skills/yt-transcript
rm -rf ~/.claude/skills/content-summarizer
rm -rf ~/.claude/skills/obsidian-note
rm -rf ~/.claude/skills/content-ideas
rm -rf ~/.claude/skills/image-generator
rm -rf ~/.claude/skills/social-posts
rm -rf ~/.claude/skills/tweet-generator
rm -rf ~/.claude/skills/youtube-pipeline
rm -rf ~/.claude/skills/skill-scaffold
rm -rf ~/.claude/skills/obsidian-vault-guide

# Remove config (optional)
rm -rf ~/.config/content-pipeline
```

### If installed via git clone

```bash
# Remove symlinks if created
rm -f ~/.claude/skills/yt-transcript
rm -f ~/.claude/skills/content-summarizer
rm -f ~/.claude/skills/obsidian-note
rm -f ~/.claude/skills/content-ideas
rm -f ~/.claude/skills/image-generator
rm -f ~/.claude/skills/social-posts
rm -f ~/.claude/skills/tweet-generator
rm -f ~/.claude/skills/youtube-pipeline
rm -f ~/.claude/skills/skill-scaffold
rm -f ~/.claude/skills/obsidian-vault-guide

# Remove the repo
rm -rf dev-environment-setup
```

---

## Troubleshooting

### Skills not showing up

- Restart Claude Code after installing
- Check skills are in the right directory:
  ```bash
  ls ~/.claude/skills/
  # OR
  ls ~/.openclaw/workspace/skills/
  ```
- Verify `SKILL.md` exists in each skill folder:
  ```bash
  ls ~/.claude/skills/yt-transcript/SKILL.md
  ```

### "Command not found: npx"

- Install Node.js: https://nodejs.org/
- Verify after install:
  ```bash
  npx --version
  ```

### Python dependency errors

- Ensure Python 3.8+:
  ```bash
  python3 --version
  ```
- Use the `--user` flag to avoid permission issues:
  ```bash
  pip3 install --user youtube-transcript-api
  ```
- If `pip3` is missing:
  ```bash
  # macOS
  brew install python3

  # Ubuntu/Debian
  sudo apt install python3-pip

  # Fedora
  sudo dnf install python3-pip
  ```

### Config not loading

- Check file exists:
  ```bash
  ls -la ~/.config/content-pipeline/.env
  ```
- Check permissions (should be `-rw-------`):
  ```bash
  chmod 600 ~/.config/content-pipeline/.env
  ```
- Test manually:
  ```bash
  source ~/.config/content-pipeline/.env && echo $GEMINI_API_KEY
  ```

### Image generation quota errors

- Free tier Gemini API has zero image generation quota
- Upgrade to a paid plan at https://ai.dev/projects
