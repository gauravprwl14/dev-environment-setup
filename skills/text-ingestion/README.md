# text-ingestion

Normalise a written notes or blog draft file into the standard `source.md` format, so the rest of the content pipeline works unchanged. Use this when your content starts from text — not a YouTube video.

## Usage

```
/text-ingestion path/to/my-notes.md
/text-ingestion path/to/draft.txt
```

## What it does

Reads a `.md` or `.txt` file and writes `source.md` to `$CONTENT_PIPELINE_OUTPUT/<date>-<slug>/` — the same output format that `/yt-transcript` produces. This lets all downstream skills (`/content-summarizer`, `/blog-generator`, etc.) work without modification.

**Accepts:**
- Raw notes (bullet lists, fragments, unstructured thoughts)
- Blog drafts (prose with structure but not yet polished)
- Mixed content (notes + prose)

**Output — `source.md`:**
```markdown
---
title: "Derived from filename or first heading"
source: written-input
date: YYYY-MM-DD
type: notes | draft
---

[normalised content body]
```

## Pipeline position

```
Written notes/draft
        ↓
/text-ingestion → source.md → /content-summarizer → summary.md → ...
                                                                    ↓
YouTube URL → /yt-transcript → transcript.md ──────────────────────┘
```

Both paths produce compatible output. Use `/content-pipeline` to handle routing automatically.

## Requirements

No API keys, no scripts — pure Claude generation.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CONTENT_PIPELINE_OUTPUT` | `~/content-pipeline/output` | Base output directory |

Set in `~/.config/content-pipeline/.env`.
