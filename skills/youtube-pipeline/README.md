# youtube-pipeline

Orchestrates the full YouTube content pipeline: given a single YouTube URL, this skill runs every downstream skill in sequence — extracting the transcript, generating a structured summary, creating an Obsidian vault note, producing content ideas with image prompts, generating marketing images via the Gemini API, and writing platform-ready social posts and tweet threads — with optional user confirmation gates between steps and graceful error recovery throughout.

## Pipeline Diagram

```
YouTube URL
    │
    ▼
[1] yt-transcript         →  transcript.md
    │
    ▼
[2] content-summarizer    →  summary.md
    │
    ├──────────────────────────────────────┐
    ▼                                      ▼
[3] obsidian-note         →  vault note   [4] content-ideas  →  ideas.md
    (optional)                                 │
                                               ├──────────────────────────┐
                                               ▼                          ▼
                                          [5] image-generator  →  images/ [6] social-posts  →  social-posts.md
                                               (optional)                  │
                                                                           ▼
                                                                      [7] tweet-generator  →  tweets.md
```

Sequential execution order: transcript → summary → obsidian → ideas → images → social → tweets

## Prerequisites

All dependent skills must be present in the same `skills/` directory:

- `yt-transcript/` — requires `youtube-transcript-api` and `yt-dlp` Python packages
- `content-summarizer/`
- `obsidian-note/` — requires a configured Obsidian vault (or set `OBSIDIAN_VAULT_PATH`)
- `content-ideas/`
- `image-generator/` — requires `GEMINI_API_KEY` and `google-genai` Python package
- `social-posts/`
- `tweet-generator/`

Optional environment variables:

| Variable | Default | Purpose |
|---|---|---|
| `CONTENT_PIPELINE_OUTPUT` | `~/content-pipeline/output/` | Base output directory |
| `OBSIDIAN_VAULT_PATH` | `/home/ubuntu/Sites/projects/gp/obsidian-vault/Ved` | Obsidian vault root |
| `GEMINI_API_KEY` | (none) | Required for image generation |

## Available Flags

| Flag | Description |
|---|---|
| `--skip-images` | Skip the image generation step (Step 5) |
| `--skip-obsidian` | Skip the Obsidian note creation step (Step 3) |
| `--only=<steps>` | Run only the specified comma-separated steps (see step names below) |
| `--no-confirm` | Skip all confirmation gates between steps (except the image cost gate) |

### Step Names for `--only`

| Name | Step | Output file |
|---|---|---|
| `transcript` | 1 — Extract transcript | `transcript.md` |
| `summary` | 2 — Generate summary | `summary.md` |
| `obsidian` | 3 — Create Obsidian note | vault note file |
| `ideas` | 4 — Generate content ideas | `ideas.md` |
| `images` | 5 — Generate images | `images/*.png` |
| `social` | 6 — Generate social posts | `social-posts.md` |
| `tweets` | 7 — Generate tweet threads | `tweets.md` |

If any step name supplied to `--only` is not in this list, the pipeline prints an error and stops before running anything.

## Examples

### Full pipeline run (with confirmation gates)

```
/youtube-pipeline https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

### Full pipeline, no prompts

```
/youtube-pipeline https://www.youtube.com/watch?v=dQw4w9WgXcQ --no-confirm
```

### Skip images and Obsidian note

```
/youtube-pipeline https://www.youtube.com/watch?v=dQw4w9WgXcQ --skip-images --skip-obsidian
```

### Partial run — transcript and summary only

```
/youtube-pipeline https://www.youtube.com/watch?v=dQw4w9WgXcQ --only=transcript,summary
```

### Partial run — generate social assets from an already-extracted transcript

```
/youtube-pipeline https://www.youtube.com/watch?v=dQw4w9WgXcQ --only=ideas,social,tweets
```

### Partial run — images and posts only, no prompts

```
/youtube-pipeline https://www.youtube.com/watch?v=dQw4w9WgXcQ --only=images,social,tweets --no-confirm
```

## Error Recovery

If any step fails mid-pipeline, the orchestrator asks whether to skip and continue or stop. A summary of completed, skipped, and failed steps is always printed at the end. When `--no-confirm` is set, failures are logged and the pipeline continues automatically.
