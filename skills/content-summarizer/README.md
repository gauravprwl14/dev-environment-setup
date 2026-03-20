# content-summarizer

Generate a deep, structured summary from a YouTube transcript or any long-form content file.

## What it does

Reads a transcript file, extracts its core argument, key topics, notable quotes, and actionable takeaways, then writes a structured `summary.md` to the same directory. The output captures thesis, complexity level, target audience, and tone — everything needed for downstream content generation.

## How it works

This is an instruction-based skill. Claude generates the output directly — no scripts or external APIs required. Claude reads your transcript file, applies the structured summarization format defined in SKILL.md, and writes the result using the Write tool.

## Usage

```
/content-summarizer path/to/transcript.md
```

Example:

```
/content-summarizer youtube-pipeline/my-video/transcript.md
```

Running the skill with no arguments prints usage instructions and stops.

## Input format

A Markdown file (typically produced by `/yt-transcript`) with YAML frontmatter containing at minimum: `title`, `channel`, `url`, `duration`. The body should be the raw or lightly formatted transcript text.

## Output format

A `summary.md` file saved to the same directory as the input. Example structure:

```markdown
---
title: "How AI Is Changing Software Development"
channel: "TechTalks"
url: "https://youtube.com/watch?v=..."
duration: "42:18"
date_summarized: "2026-03-20"
type: content-summary
---

# Summary: How AI Is Changing Software Development

## Thesis
AI is not replacing developers but dramatically shifting which skills matter most.

## Key Topics
### Pair Programming with AI
- **What:** Using LLMs as real-time coding assistants
- **Why it matters:** Reduces boilerplate time by ~60%
- **Key details:** Tools like Claude Code, Copilot, Cursor

## Notable Quotes
> "The best engineers in 2026 are the ones who prompt well."
> — TechTalks

## Key Takeaways
1. Learn to write precise prompts, not just code
2. ...

## Content Metadata
- **Word count:** ~8,400
- **Key themes:** AI, developer productivity, future of work
- **Complexity:** intermediate
```

## Pipeline context

- **Receives from:** `/yt-transcript` — a raw transcript `.md` file
- **Feeds into:** `/content-ideas` (pass `summary.md` as input) or `/obsidian-note` for personal knowledge management

Typical pipeline: `/yt-transcript` → `/content-summarizer` → `/content-ideas` → `/social-posts` or `/tweet-generator`

## Tips

- If the transcript is messy or auto-generated, the summary will still work — Claude handles noise well, but cleaner input yields more precise quotes.
- For very long transcripts (60+ minutes), the output may be lengthy. That is intentional — use `/content-ideas` to filter down to what's worth posting.
- The `date_summarized` field is set automatically to today's date. If you are batch-processing older transcripts, you can edit the frontmatter afterward.
