# yt-transcript

Extract the full transcript from any YouTube video URL. Returns a clean markdown file with video metadata and timestamped content.

## Usage

```
/yt-transcript https://www.youtube.com/watch?v=VIDEO_ID
```

## What it does

1. Extracts transcript using `youtube-transcript-api` (primary) or `yt-dlp` (fallback)
2. Creates an output directory: `<CONTENT_PIPELINE_OUTPUT>/<YYYY-MM-DD-HH-MM-slug>/`
3. Saves `transcript.md` with video title, URL, duration, and full transcript

## Output

```
output/2026-03-20-14-30-how-ai-changes-dev/
└── transcript.md
```

**transcript.md structure:**
```markdown
---
title: "How AI is Changing Software Development"
url: https://youtube.com/watch?v=abc123
date: 2026-03-20
duration: 12:34
source: youtube-transcript-api
---

# How AI is Changing Software Development

[00:00] Welcome to today's video...
[00:15] We're going to talk about...
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CONTENT_PIPELINE_OUTPUT` | `~/content-pipeline/output` | Base output directory |

Set in `~/.config/content-pipeline/.env`.

## Requirements

- Python 3.8+
- `youtube-transcript-api>=1.2.4` — Primary transcript source
- `yt-dlp` — Fallback for auto-generated captions

```bash
pip install youtube-transcript-api yt-dlp
```

## Error handling

| Error | Cause | Response |
|-------|-------|----------|
| No captions available | Video has no manual or auto-generated subtitles | Clear error message, no file created |
| Invalid URL | Not a YouTube URL | Validation error before any network call |
| Network error | Connection issue | Error with retry suggestion |

## Pipeline position

```
/yt-transcript → transcript.md → /content-summarizer → summary.md → ...
```
