# Configuration Reference

All pipeline configuration lives in a single file in your home directory. API keys never touch any repository.

---

## The Config File

**Location:**
```
~/.config/content-pipeline/.env
```

**Format:** Standard `.env` — one `KEY=value` per line, `#` for comments.

**Create it:**
```bash
mkdir -p ~/.config/content-pipeline
nano ~/.config/content-pipeline/.env
```

**Edit it later:**
```bash
nano ~/.config/content-pipeline/.env
# or
code ~/.config/content-pipeline/.env
```

---

## All Variables Reference

| Variable | Default | Required | Description |
|---|---|---|---|
| `CONTENT_PIPELINE_OUTPUT` | `~/content-pipeline/output` | No | Root directory where all pipeline output files are saved |
| `OBSIDIAN_VAULT_PATH` | *(empty — Obsidian skipped)* | No | Absolute path to your Obsidian vault |
| `GEMINI_API_KEY` | *(none)* | For image generation | Google Gemini API key |
| `HASHNODE_API_KEY` | *(none)* | For Hashnode publishing | Hashnode Personal Access Token |
| `HASHNODE_PUBLICATION_ID` | *(none)* | For Hashnode publishing | Hashnode publication (blog) ID |
| `CONTENT_PIPELINE_LOG_DIR` | `~/.config/content-pipeline/logs` | No | Where Hashnode publish logs are written |

---

## Priority Order

When the same variable is set in multiple places, the highest-priority source wins:

1. **Shell environment variable** (highest priority)
   ```bash
   export CONTENT_PIPELINE_OUTPUT=~/override
   ```
2. **`~/.config/content-pipeline/.env`** — the shared config file (recommended place to set values)
3. **`~/.config/<skill-name>/.env`** — per-skill overrides (advanced, rarely needed)
4. **Built-in defaults** (lowest priority — see table above)

In practice, edit the shared `.env` file (#2) and leave everything else alone.

---

## What Each Variable Controls

### `CONTENT_PIPELINE_OUTPUT`

The root directory where all pipeline output is written.

Every pipeline run creates a subdirectory named by date and video slug:
```
$CONTENT_PIPELINE_OUTPUT/<YYYY-MM-DD>-<video-slug>/
```

Inside that subdirectory, the pipeline writes:
- `transcript.md` — raw video transcript
- `summary.md` — AI-generated summary
- `ideas.md` — content idea extraction
- `prompts.md` — image generation prompts
- `images/` — generated images
- `social-posts.md` — social media copy
- `tweets.md` — tweet thread
- `blog.md` — full blog post draft

The directory is created automatically if it does not exist.

---

### `OBSIDIAN_VAULT_PATH`

Absolute path to your Obsidian vault root.

Used by the skills: `obsidian-note`, `text-ingestion`, `youtube-pipeline`.

Notes are saved to:
```
$OBSIDIAN_VAULT_PATH/content/yt-content/<YYYY-MM-DD>-<slug>.md
```

If left empty (the default), the `obsidian-note` step is skipped automatically in pipeline runs. You can also pass `--skip-obsidian` explicitly to skip it regardless of this setting.

Leave this empty if you do not use Obsidian — the rest of the pipeline is unaffected.

---

### `GEMINI_API_KEY`

Google Gemini API key used by the `image-generator` Python script to generate images from prompts.

**Not needed for `gemini-prompt-generator`** — that skill only generates image prompts for manual use and is free.

Image generation requires a Google Cloud project with billing enabled.

Get a key: [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)

---

### `HASHNODE_API_KEY` and `HASHNODE_PUBLICATION_ID`

Both are required together to publish blog posts to Hashnode. They are used by the `hashnode` Node.js scripts.

**`HASHNODE_API_KEY`** — your Personal Access Token.
Get it: Hashnode → Account Settings → Developer → Personal Access Token

**`HASHNODE_PUBLICATION_ID`** — the ID of the blog you want to publish to.
Find it: `hashnode.com/dashboards/<ID>/general` — the `<ID>` segment is your publication ID.

---

### `CONTENT_PIPELINE_LOG_DIR`

Directory where Hashnode publish action logs are stored.

Default path: `~/.config/content-pipeline/logs/hashnode-publish-log.json`

You rarely need to change this. Override it only if you want logs in a different location (e.g., a shared drive or a project-specific folder).

---

## Minimal Config

Most of the pipeline works without any API keys. The following is sufficient to run transcript extraction, summarization, idea generation, prompt generation, social posts, tweets, and blog drafting:

```bash
# ~/.config/content-pipeline/.env
CONTENT_PIPELINE_OUTPUT=~/my-content/output
```

Add API keys only when you need image generation (`GEMINI_API_KEY`) or Hashnode publishing (`HASHNODE_API_KEY` + `HASHNODE_PUBLICATION_ID`).

---

## Full Annotated Example

```bash
# ~/.config/content-pipeline/.env
# Content Pipeline Configuration

# ── Output paths ──────────────────────────────────────────────────────────────
# Where all pipeline files are saved (transcripts, summaries, ideas, etc.)
CONTENT_PIPELINE_OUTPUT=~/Sites/projects/content/output

# Path to your Obsidian vault (leave empty to skip Obsidian steps)
OBSIDIAN_VAULT_PATH=~/obsidian

# ── API keys ──────────────────────────────────────────────────────────────────
# Required for /image-generator (NOT required for /gemini-prompt-generator)
# Get from: https://aistudio.google.com/app/apikey
GEMINI_API_KEY=AIzaSy...

# Required for /hashnode publishing
# API key: https://hashnode.com/settings/developer → Personal Access Token
HASHNODE_API_KEY=your-personal-access-token
# Publication ID from: hashnode.com/dashboards/<ID>/general
HASHNODE_PUBLICATION_ID=your-publication-id

# ── Optional overrides ────────────────────────────────────────────────────────
# Where Hashnode publish logs are stored (default shown)
# CONTENT_PIPELINE_LOG_DIR=~/.config/content-pipeline/logs
```

---

## Quick Commands

### Edit config
```bash
nano ~/.config/content-pipeline/.env
# or
code ~/.config/content-pipeline/.env
```

### Verify config is loaded correctly
```bash
bash /path/to/dev-environment-setup/skills/install.sh --check
```

The check output shows current values for `CONTENT_PIPELINE_OUTPUT`, `GEMINI_API_KEY`, `HASHNODE_API_KEY`, and `HASHNODE_PUBLICATION_ID`. Key values are truncated for safety.

### Per-skill override (advanced)

If you need a specific skill to use different settings from the shared config, create a per-skill `.env`:

```bash
mkdir -p ~/.config/yt-transcript
cat > ~/.config/yt-transcript/.env << 'EOF'
CONTENT_PIPELINE_OUTPUT=~/custom-transcript-output
EOF
```

Note: the shared `~/.config/content-pipeline/.env` wins over the per-skill file for any key present in both. Per-skill files only take effect for keys not set in the shared file.
