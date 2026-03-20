# content-pipeline

Unified content pipeline orchestrator. Accepts a YouTube URL **or** a written notes/draft file and produces a complete suite of content assets: blog post, carousel, Instagram caption, social posts, tweet threads, images, and Obsidian note.

This skill replaces and extends `youtube-pipeline` with support for written input.

## Usage

```
# From a YouTube URL
/content-pipeline https://youtube.com/watch?v=VIDEO_ID

# From a written notes or draft file
/content-pipeline path/to/my-notes.md
```

## What it does

**YouTube input:** Calls `/yt-transcript` → `/content-summarizer` → pipeline
**Written input:** Calls `/text-ingestion` → `/content-summarizer` → pipeline

**Pipeline steps:**

| Step | Skill | Output |
|------|-------|--------|
| ingest | yt-transcript or text-ingestion | source.md / transcript.md |
| summary | content-summarizer | summary.md |
| blog | blog-generator | blog.md |
| ideas | content-ideas | ideas.md |
| carousel | carousel-generator | carousel.md |
| instagram | instagram-caption | instagram.md |
| social | social-posts | social-posts.md |
| tweets | tweet-generator | tweets.md |
| images | image-generator | images/ |
| obsidian | obsidian-note | vault note |
| hashnode | hashnode | Hashnode draft |

## Flags

```
/content-pipeline <input> [flags]
  --skip-blog       Skip blog generation
  --skip-images     Skip image generation (avoids API cost)
  --skip-obsidian   Skip Obsidian note
  --only=<steps>    Run only these steps (comma-separated)
  --no-confirm      Skip confirmation gates
```

Valid step names: `ingest`, `summary`, `blog`, `ideas`, `carousel`, `instagram`, `social`, `tweets`, `images`, `obsidian`, `hashnode`

## vs. youtube-pipeline

| Feature | youtube-pipeline | content-pipeline |
|---------|-----------------|-----------------|
| YouTube URL input | ✅ | ✅ |
| Written notes input | ❌ | ✅ |
| Blog post generation | ❌ | ✅ |
| Carousel generation | ❌ | ✅ |
| Instagram caption | ❌ | ✅ |
| Hashnode publishing | ❌ | ✅ |

## Requirements

- `GEMINI_API_KEY` — for image generation (optional, skip with `--skip-images`)
- `HASHNODE_API_KEY` + `HASHNODE_PUBLICATION_ID` — for Hashnode step (optional)
- `OBSIDIAN_VAULT_PATH` — for Obsidian step (optional, skip with `--skip-obsidian`)
