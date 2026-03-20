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

## Install Steps

### 1. Clone the repo

```bash
git clone https://github.com/gauravprwl14/dev-environment-setup.git
cd dev-environment-setup
```

### 2. Install skills into your Claude Code project

Navigate to the project where you want the skills, then:

```bash
npx skills install /path/to/dev-environment-setup/skills --yes
```

This installs all 17 skills to `.agents/skills/` in your current directory and makes them available as `/commands` in Claude Code.

**Example:**
```bash
cd ~/my-content-project
npx skills install ~/dev-environment-setup/skills --yes
```

### 3. Install Python dependencies

```bash
pip install \
  "youtube-transcript-api>=1.2.4" \
  yt-dlp \
  "google-genai>=1.0.0" \
  "Pillow>=10.0.0"
```

### 4. Install Node.js dependencies (for Hashnode publishing)

```bash
cd /path/to/dev-environment-setup/skills/hashnode/scripts
npm install
```

### 5. Configure API keys

Create the shared pipeline config:

```bash
mkdir -p ~/.config/content-pipeline
cat > ~/.config/content-pipeline/.env << 'EOF'
# Output directory for all pipeline files
CONTENT_PIPELINE_OUTPUT=~/my-content-project/output

# Obsidian vault (optional — skip with --skip-obsidian if not using Obsidian)
OBSIDIAN_VAULT_PATH=~/path/to/obsidian/vault

# Gemini API key — required for /image-generator
# Get from: https://aistudio.google.com/app/apikey
# Note: Image generation requires billing enabled on your Google Cloud project
GEMINI_API_KEY=your-key-here

# Hashnode — required for /hashnode
# Personal Access Token: https://hashnode.com/settings/developer
HASHNODE_API_KEY=your-token-here
# Publication ID from dashboard URL: hashnode.com/dashboards/<ID>/general
HASHNODE_PUBLICATION_ID=your-publication-id-here
EOF
```

### 6. Open in Claude Code and test

```bash
claude .
```

Then in Claude Code:
```
/yt-transcript https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

Expected: transcript extracted and saved to `output/<date>-<slug>/transcript.md`.

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
