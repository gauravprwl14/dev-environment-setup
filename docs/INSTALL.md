# Installing the Content Pipeline Skills

This guide covers installing the content pipeline skills into any Claude Code project from the GitHub repository.

## What You're Installing

A set of 17 Claude Code skills that transform a YouTube URL into complete content assets:

```
YouTube URL → transcript → summary → ideas → prompts → images → social posts → tweets
```

Skills work as Claude Code slash commands: `/youtube-pipeline`, `/yt-transcript`, `/content-ideas`, etc.

---

## Prerequisites

| Tool | Minimum Version | Install |
|------|----------------|---------|
| [Claude Code](https://claude.ai/code) | Latest | `npm install -g @anthropic-ai/claude-code` |
| Node.js | 16+ | [nodejs.org](https://nodejs.org) |
| Python | 3.8+ | [python.org](https://python.org) |
| npx | ships with npm 5.2+ | — |

---

## Quick Install (automated)

### 1. Clone the repo

```bash
git clone https://github.com/gauravprwl14/dev-environment-setup.git
```

### 2. Run the installer from your target project directory

```bash
cd ~/my-content-project
bash ~/dev-environment-setup/skills/install.sh
```

The installer:
- Checks all system dependencies (Node.js ≥16, Python ≥3.8, pip, npm, yt-dlp)
- Installs Python packages from `requirements.txt`
- Installs Node.js packages for Hashnode
- Installs all 17 skills via `npx skills`
- Creates `~/.config/content-pipeline/.env` with placeholders

### 3. Add your API keys

```bash
nano ~/.config/content-pipeline/.env
```

See [API Keys Reference](#api-keys-reference) below.

### 4. Open in Claude Code and test

```bash
claude .
```

Then in Claude Code:
```
/yt-transcript https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

Expected: transcript extracted and saved to `output/<date>-<slug>/transcript.md`.

---

## Installer Options

```bash
# Check dependencies only — don't install anything
bash skills/install.sh --check

# Install skills only (skip pip/npm installs)
bash skills/install.sh --skills-only

# Create config file only
bash skills/install.sh --config-only

# Set a custom output directory
bash skills/install.sh --output-dir ~/my-output

# Show all options
bash skills/install.sh --help
```

---

## Manual Install Steps

If you prefer to install step-by-step:

---

## API Keys Reference

### Gemini API Key
- **Used by:** `/image-generator`
- **Not needed for:** `/gemini-prompt-generator` (generates prompts for manual use — free)
- **Get it:** [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
- **Billing note:** Image generation (`imagen-4`, `gemini-*-image` models) requires billing enabled on the linked Google Cloud project. Free tier quota for image generation is 0.

### Hashnode API Key + Publication ID
- **Used by:** `/hashnode`
- **Get API key:** [hashnode.com/settings/developer](https://hashnode.com/settings/developer) → Generate Personal Access Token
- **Find Publication ID:** Open your Hashnode dashboard → URL contains `hashnode.com/dashboards/<ID>/general`

---

## Config File Reference

Location: `~/.config/content-pipeline/.env`

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `CONTENT_PIPELINE_OUTPUT` | No | `~/content-pipeline/output` | Where all pipeline output files are saved |
| `OBSIDIAN_VAULT_PATH` | No | *(empty)* | Path to Obsidian vault for note creation |
| `GEMINI_API_KEY` | For images | *(none)* | Google Gemini API key |
| `HASHNODE_API_KEY` | For Hashnode | *(none)* | Hashnode Personal Access Token |
| `HASHNODE_PUBLICATION_ID` | For Hashnode | *(none)* | Hashnode publication (blog) ID |

**Config loading priority** (highest wins):
1. Shell environment variables (`export VAR=value`)
2. `~/.config/content-pipeline/.env` ← recommended
3. `~/.config/<skill-name>/.env` (per-skill overrides)
4. Built-in defaults

---

## Minimum-Dependency Install (no API keys)

If you don't have API keys, you can still use most of the pipeline. These skills work with zero API keys:

| Skill | Works without keys? |
|-------|-------------------|
| `/yt-transcript` | ✅ Yes |
| `/content-summarizer` | ✅ Yes (Claude processes locally) |
| `/obsidian-note` | ✅ Yes (needs local vault) |
| `/content-ideas` | ✅ Yes |
| `/gemini-prompt-generator` | ✅ Yes (generates prompts for manual use) |
| `/social-posts` | ✅ Yes |
| `/tweet-generator` | ✅ Yes |
| `/blog-generator` | ✅ Yes |
| `/carousel-generator` | ✅ Yes |
| `/instagram-caption` | ✅ Yes |
| `/image-generator` | ❌ Requires `GEMINI_API_KEY` + billing |
| `/hashnode` | ❌ Requires `HASHNODE_API_KEY` + `HASHNODE_PUBLICATION_ID` |

**Minimum install for no-key pipeline:**
```bash
pip install youtube-transcript-api yt-dlp
```

---

## Troubleshooting

### `/yt-transcript` fails with "No captions available"
The video has no captions (manual or auto-generated). Try a different video, or check YouTube's caption settings for that video.

### Image generation returns 429 or quota error
Your Google Cloud project doesn't have billing enabled, or the free-tier quota (0 for image models) is exhausted. Enable billing at [console.cloud.google.com](https://console.cloud.google.com) or use `/gemini-prompt-generator` and paste prompts manually into gemini.google.com.

### Hashnode returns 400 error
Verify that:
1. `HASHNODE_API_KEY` is a valid Personal Access Token (not an OAuth token)
2. `HASHNODE_PUBLICATION_ID` is the correct ID (from your dashboard URL)

### Skills not showing as `/commands`
Reinstall:
```bash
npx skills install /path/to/dev-environment-setup/skills --yes
```
Then restart Claude Code.

### `CONTENT_PIPELINE_OUTPUT` not respected
The pipeline reads from `~/.config/content-pipeline/.env`, not from a `.env` in your project directory. Ensure the file exists at the right path:
```bash
cat ~/.config/content-pipeline/.env | grep CONTENT_PIPELINE_OUTPUT
```

---

## Updating Skills

When the dev-environment-setup repo has updates:

```bash
cd /path/to/dev-environment-setup
git pull
npx skills install ./skills --yes  # reinstall from your project
```
