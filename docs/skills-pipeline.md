# YouTube Content Pipeline — Knowledge Transfer Guide

Complete documentation for the multi-agent skill pipeline: YouTube URL → transcript → summary → Obsidian note → content ideas → images → social posts → tweets.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture Overview](#architecture-overview)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Skills Reference](#skills-reference)
6. [Adding Skills to Claude Code](#adding-skills-to-claude-code)
7. [Adding Skills to OpenClaw](#adding-skills-to-openclaw)
8. [Pipeline Usage](#pipeline-usage)
9. [Adding a New Skill](#adding-a-new-skill)
10. [Troubleshooting](#troubleshooting)

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/gp/dev-environment-setup.git
cd dev-environment-setup

# 2. Install Python dependencies
pip3 install --user youtube-transcript-api>=1.2.4 yt-dlp google-genai>=1.0.0 Pillow>=10.0.0

# 3. Set up config
mkdir -p ~/.config/content-pipeline && chmod 700 ~/.config/content-pipeline
cat > ~/.config/content-pipeline/.env << 'EOF'
GEMINI_API_KEY=your-gemini-api-key
CONTENT_PIPELINE_OUTPUT=~/content-pipeline/output
OBSIDIAN_VAULT_PATH=/path/to/your/obsidian/vault
EOF
chmod 600 ~/.config/content-pipeline/.env

# 4. Run the full pipeline
/youtube-pipeline https://www.youtube.com/watch?v=VIDEO_ID
```

---

## Architecture Overview

```
YouTube URL
    │
    ▼
/yt-transcript ──────────► transcript.md     (Python: youtube-transcript-api + yt-dlp)
    │
    ▼
/content-summarizer ─────► summary.md        (Pure Claude)
    │
    ├──► /obsidian-note ─► vault note         (Pure Claude + obsidian-cli)
    │
    ▼
/content-ideas ──────────► ideas.md           (Pure Claude)
    │
    ├──► /image-generator ► images/           (Python: Gemini 3 Flash Image API)
    │
    ├──► /social-posts ──► social-posts.md    (Pure Claude)
    │
    └──► /tweet-generator ► tweets.md         (Pure Claude)
```

**Output directory structure:**
```
~/content-pipeline/output/
└── YYYY-MM-DD-slug/
    ├── transcript.md
    ├── summary.md
    ├── ideas.md
    ├── social-posts.md
    ├── tweets.md
    └── images/
        ├── idea-1-slug-1600x900.png
        ├── idea-1-slug-1200x627.png
        └── manifest.json
```

---

## Installation

### Method 1: Install all skills via npx (for Claude Code users)

```bash
npx skills i gp/dev-environment-setup
```

### Method 2: Install a single skill

```bash
npx skills i gp/dev-environment-setup --skill yt-transcript
npx skills i gp/dev-environment-setup --skill content-summarizer
npx skills i gp/dev-environment-setup --skill image-generator
# ... etc
```

### Method 3: Local development (clone repo)

```bash
git clone https://github.com/gp/dev-environment-setup.git
cd dev-environment-setup
# Skills are at ./skills/ — Claude Code auto-discovers them
```

### Method 4: Install Nano Banana Pro (external skill)

```bash
npx skills i YouMind-OpenLab/nano-banana-pro-prompts-recommend-skill
```

### Python Dependencies

```bash
# Required for /yt-transcript
pip3 install --user youtube-transcript-api>=1.2.4
pip3 install --user yt-dlp

# Required for /image-generator
pip3 install --user google-genai>=1.0.0
pip3 install --user Pillow>=10.0.0
```

---

## Configuration

### Environment Variables

All configuration lives in `~/.config/content-pipeline/.env`:

```bash
mkdir -p ~/.config/content-pipeline && chmod 700 ~/.config/content-pipeline
chmod 600 ~/.config/content-pipeline/.env
```

| Variable | Required For | Default | Description |
|----------|-------------|---------|-------------|
| `GEMINI_API_KEY` | `/image-generator` | — | Google Gemini API key ([get one](https://ai.dev)) |
| `CONTENT_PIPELINE_OUTPUT` | All skills | `~/content-pipeline/output/` | Base output directory |
| `OBSIDIAN_VAULT_PATH` | `/obsidian-note` | — | Absolute path to Obsidian vault root |

### Example .env

```bash
GEMINI_API_KEY=AIzaSy...your-key
CONTENT_PIPELINE_OUTPUT=~/content-pipeline/output
OBSIDIAN_VAULT_PATH=/home/ubuntu/home/project/gp/obsidian-vault/Ved
```

### Gemini API Key Setup

1. Go to https://ai.dev and create a project
2. Generate an API key
3. **Important:** Image generation requires a **paid plan** (Imagen models) or a plan with image generation quota (Gemini Flash Image models)
4. The script uses **Gemini 3 Flash Image** as the primary model — fast, good quality, cost-effective

### Security Notes

- Config directory has `700` permissions (owner-only access)
- `.env` file has `600` permissions (owner read/write only)
- API keys are never committed to git
- Skills load env via `source ~/.config/content-pipeline/.env 2>/dev/null`

---

## Skills Reference

### User-Invocable Skills

| Skill | Command | Type | Description |
|-------|---------|------|-------------|
| yt-transcript | `/yt-transcript <url>` | Python + Claude | Extract full transcript from YouTube video |
| content-summarizer | `/content-summarizer <path>` | Pure Claude | Structured summary with topics, quotes, takeaways |
| obsidian-note | `/obsidian-note <path>` | Pure Claude | Create Obsidian vault note with wikilinks, callouts |
| content-ideas | `/content-ideas <path>` | Pure Claude | 5-10 content ideas with image prompts |
| image-generator | `/image-generator <path>` | Python + Claude | Generate images via Gemini API |
| social-posts | `/social-posts <path>` | Pure Claude | X + LinkedIn posts paired with images |
| tweet-generator | `/tweet-generator <path>` | Pure Claude | 3-5 tweet threads, 5-12 tweets each |
| youtube-pipeline | `/youtube-pipeline <url>` | Orchestrator | Full pipeline with user gates |
| skill-scaffold | `/skill-scaffold <name>` | Pure Claude | Generate new skill boilerplate |

### Background Skills (not user-invocable)

| Skill | Description |
|-------|-------------|
| obsidian-vault-guide | Vault conventions, naming, wikilink rules — loaded by obsidian-note |

### Pipeline Orchestrator Flags

```bash
/youtube-pipeline <url> [OPTIONS]

Options:
  --skip-images      Skip image generation step
  --skip-obsidian    Skip Obsidian note creation
  --only=<steps>     Run only specified steps (comma-separated)
  --no-confirm       Skip user confirmation gates between steps

Valid steps: transcript, summary, obsidian, ideas, images, social, tweets
```

**Examples:**
```bash
# Full pipeline with all steps
/youtube-pipeline https://youtube.com/watch?v=VIDEO_ID

# Quick: transcript + summary only
/youtube-pipeline https://youtube.com/watch?v=VIDEO_ID --only=transcript,summary

# Skip expensive steps
/youtube-pipeline https://youtube.com/watch?v=VIDEO_ID --skip-images

# Fully automated (no confirmations)
/youtube-pipeline https://youtube.com/watch?v=VIDEO_ID --no-confirm
```

---

## Adding Skills to Claude Code

Claude Code auto-discovers skills from the `skills/` directory. There are three ways to set this up:

### Option A: Project-level skills (recommended for development)

If you cloned this repo and are working inside it, Claude Code auto-discovers skills from `./skills/` automatically. No configuration needed.

```
dev-environment-setup/
└── skills/
    ├── .claude-plugin/
    │   └── plugin.json          ← monorepo manifest
    ├── yt-transcript/
    │   └── SKILL.md             ← auto-discovered
    ├── content-summarizer/
    │   └── SKILL.md
    └── ...
```

Just open the project in Claude Code:
```bash
cd dev-environment-setup
claude
```

All skills are available immediately via `/skill-name`.

### Option B: Install globally via npx

```bash
npx skills i gp/dev-environment-setup
```

This installs skills to `~/.claude/skills/` where Claude Code discovers them across all projects.

### Option C: Manual installation

Copy the skill directories to your Claude Code skills location:

```bash
# Copy all skills
cp -r skills/* ~/.claude/skills/

# Or copy a single skill
cp -r skills/yt-transcript ~/.claude/skills/
```

### Verifying Skills are Loaded

In a Claude Code session, type `/` and you should see the skill names in autocomplete. Or invoke a skill with no arguments:

```
/yt-transcript
```

Expected response: `"YouTube Transcript loaded. Usage: /yt-transcript <youtube-url>"`

### How Claude Code Discovers Skills

1. On startup, Claude Code scans `./skills/` and `~/.claude/skills/`
2. Reads the YAML frontmatter from each `SKILL.md` (name + description)
3. Adds skill descriptions to the system prompt
4. When a user message matches a skill's description, Claude loads the full SKILL.md
5. This is called **progressive disclosure** — skills are loaded on-demand, not all at once

### SKILL.md Anatomy

```yaml
---
name: skill-name                    # Unique identifier (kebab-case)
description: "Trigger description"  # When should this skill activate
argument-hint: 'example usage'      # Shown in autocomplete
allowed-tools: Bash, Read, Write    # Tools this skill can use
user-invocable: false               # Set to false for background skills
---

# Skill Title

## Execution Logic
[How to parse $ARGUMENTS and decide what to do]

## Task Execution
[Step-by-step instructions for Claude]
```

### Key: The `$ARGUMENTS` Variable

When a user invokes `/skill-name some text here`, the `some text here` part is available as `$ARGUMENTS`. Skills check this to determine execution mode:

- **Empty** → show usage info and stop
- **Has content** → parse and execute

---

## Adding Skills to OpenClaw

OpenClaw uses explicit plugin registration. Each skill needs a `.claude-plugin/plugin.json`.

### Option A: Point OpenClaw to this repo

In your OpenClaw workspace config, add the skills directory:

```bash
# In ~/.openclaw/workspace/ or your OpenClaw workspace:
ln -s /path/to/dev-environment-setup/skills ~/.openclaw/workspace/skills/youtube-pipeline
```

### Option B: Copy skills to OpenClaw's skill directory

```bash
cp -r skills/* ~/.openclaw/workspace/skills/
```

### Option C: Install via npx

```bash
npx skills i gp/dev-environment-setup
```

When prompted, select **OpenClaw** as the target.

### Plugin.json Format (OpenClaw)

Each skill has `.claude-plugin/plugin.json`:

```json
{
  "name": "yt-transcript",
  "description": "Extract transcript from any YouTube video URL",
  "version": "1.0.0",
  "author": { "name": "gp" },
  "repository": "https://github.com/gp/dev-environment-setup",
  "license": "MIT",
  "keywords": ["youtube", "transcript"],
  "skills": ["./"]
}
```

The `"skills": ["./"]` field tells OpenClaw where SKILL.md is relative to the plugin.json.

### Monorepo Marketplace Manifest

The root `skills/.claude-plugin/marketplace.json` registers all skills:

```json
{
  "name": "youtube-content-pipeline",
  "owner": { "name": "gp", "url": "https://github.com/gp" },
  "metadata": { "description": "Multi-agent YouTube content pipeline" },
  "plugins": [
    { "name": "yt-transcript", "source": "./yt-transcript" },
    { "name": "content-summarizer", "source": "./content-summarizer" },
    ...
  ]
}
```

### OpenClaw Skill Management

If using OpenClaw's skill-ctl:

```bash
# List installed skills
./skill-ctl.sh list

# Enable/disable a skill
./skill-ctl.sh enable yt-transcript
./skill-ctl.sh disable image-generator
```

---

## Pipeline Usage

### Full Pipeline Example

```bash
# Invoke the orchestrator
/youtube-pipeline https://www.youtube.com/watch?v=_h2EnRfxMQE
```

This will:
1. Extract transcript → `transcript.md`
2. Ask: "Continue to summary?" → Generate `summary.md`
3. Ask: "Continue to Obsidian note?" → Create vault note + update MOC
4. Ask: "Continue to content ideas?" → Generate `ideas.md`
5. Ask: "Continue to image generation?" → Generate `images/` (needs GEMINI_API_KEY)
6. Ask: "Continue to social posts?" → Generate `social-posts.md`
7. Ask: "Continue to tweets?" → Generate `tweets.md`

### Individual Skill Usage

```bash
# Step 1: Get transcript
/yt-transcript https://www.youtube.com/watch?v=VIDEO_ID

# Step 2: Summarize
/content-summarizer ~/content-pipeline/output/2026-03-08-slug/transcript.md

# Step 3: Create Obsidian note
/obsidian-note ~/content-pipeline/output/2026-03-08-slug/summary.md

# Step 4: Generate ideas
/content-ideas ~/content-pipeline/output/2026-03-08-slug/summary.md

# Step 5: Generate images (needs GEMINI_API_KEY)
/image-generator ~/content-pipeline/output/2026-03-08-slug/ideas.md

# Step 6: Generate posts
/social-posts ~/content-pipeline/output/2026-03-08-slug/ideas.md

# Step 7: Generate threads
/tweet-generator ~/content-pipeline/output/2026-03-08-slug/ideas.md
```

### Direct Image Generation

```bash
/image-generator --prompt "A futuristic city at sunset, cyberpunk style"
```

---

## Adding a New Skill

### Using the Scaffold

```bash
# Basic skill
/skill-scaffold my-new-skill

# With Python scripts
/skill-scaffold my-new-skill --with-python

# With shell scripts
/skill-scaffold my-new-skill --with-scripts
```

This creates:
```
skills/my-new-skill/
├── SKILL.md                    ← Edit this to define behavior
├── .claude-plugin/
│   └── plugin.json
└── scripts/                    ← Only if --with-python or --with-scripts
    ├── my_new_skill.py
    └── requirements.txt
```

### Manual Steps After Scaffolding

1. **Edit SKILL.md** — define the execution logic, task steps, and output format
2. **Update root plugin.json** — add the skill to `skills/.claude-plugin/plugin.json`'s `skills` array
3. **Update marketplace.json** — add the skill to `skills/.claude-plugin/marketplace.json`'s `plugins` array
4. **Test** — invoke `/my-new-skill` with no args to verify it loads

### Skill Design Principles

- **One skill = one task** — don't overload a skill with multiple responsibilities
- **Check `$ARGUMENTS`** — empty = show usage, non-empty = execute
- **Progressive disclosure** — keep SKILL.md concise, put reference data in `references/`
- **Idempotent** — safe to run multiple times
- **Clear output** — tell the user what was created and what to do next

---

## Troubleshooting

### "Skill not found" when invoking /skill-name

- Ensure the skill directory is in `./skills/` or `~/.claude/skills/`
- Verify `SKILL.md` exists and has valid YAML frontmatter
- Check that the `name` field in frontmatter matches the directory name
- Restart Claude Code to re-scan skills

### Transcript extraction fails

```bash
# Check dependencies
pip3 list | grep -i youtube
pip3 list | grep -i yt-dlp

# Test directly
python3 skills/yt-transcript/scripts/extract.py "https://youtube.com/watch?v=dQw4w9WgXcQ"
```

- **"No captions available"** — video has no subtitles; yt-dlp fallback also found nothing
- **"Invalid YouTube URL"** — check URL format (must be youtube.com or youtu.be)
- **Network errors** — check internet connection

### Image generation fails

```bash
# Check API key is set
source ~/.config/content-pipeline/.env && echo $GEMINI_API_KEY

# Test directly
export GEMINI_API_KEY=your-key
python3 skills/image-generator/scripts/generate_image.py --prompt "test" --output-dir /tmp/test
```

- **"GEMINI_API_KEY not set"** — add key to `~/.config/content-pipeline/.env`
- **"quota exceeded" / "limit: 0"** — your Gemini API plan doesn't include image generation; upgrade to a paid plan at https://ai.dev
- **"model not found"** — the script auto-detects available models; if none match, list them: `python3 -c "from google import genai; c = genai.Client(api_key='KEY'); [print(m.name) for m in c.models.list() if 'image' in m.name.lower()]"`

### Obsidian note not created

- Verify `OBSIDIAN_VAULT_PATH` is set in `.env`
- Verify the vault path exists: `ls $OBSIDIAN_VAULT_PATH`
- Ensure `content/yt-content/` subdirectory exists or can be created

### Pipeline stops at a step

- Use `--no-confirm` to skip confirmation gates
- Use `--only=transcript,summary` to run specific steps
- Use `--skip-images` if you don't have a Gemini API key

---

## File Reference

```
skills/
├── .claude-plugin/
│   ├── plugin.json              # Root monorepo manifest
│   └── marketplace.json         # Marketplace discovery metadata
├── yt-transcript/               # YouTube transcript extractor
│   ├── SKILL.md
│   ├── .claude-plugin/plugin.json
│   └── scripts/
│       ├── extract.py           # Main extraction script
│       └── requirements.txt
├── content-summarizer/          # Structured content summarizer
│   ├── SKILL.md
│   └── .claude-plugin/plugin.json
├── obsidian-note/               # Obsidian vault note creator
│   ├── SKILL.md
│   └── .claude-plugin/plugin.json
├── obsidian-vault-guide/        # Background vault conventions
│   ├── SKILL.md
│   └── .claude-plugin/plugin.json
├── content-ideas/               # Content idea generator
│   ├── SKILL.md
│   └── .claude-plugin/plugin.json
├── image-generator/             # Gemini image generator
│   ├── SKILL.md
│   ├── .claude-plugin/plugin.json
│   └── scripts/
│       ├── generate_image.py    # Gemini 3 Flash Image script
│       └── requirements.txt
├── social-posts/                # X + LinkedIn post generator
│   ├── SKILL.md
│   └── .claude-plugin/plugin.json
├── tweet-generator/             # Tweet thread generator
│   ├── SKILL.md
│   └── .claude-plugin/plugin.json
├── youtube-pipeline/            # Full pipeline orchestrator
│   ├── SKILL.md
│   └── .claude-plugin/plugin.json
└── skill-scaffold/              # Skill boilerplate generator
    ├── SKILL.md
    └── .claude-plugin/plugin.json
```
