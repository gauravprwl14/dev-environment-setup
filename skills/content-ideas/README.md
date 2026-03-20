# content-ideas

Generate 5-10 ready-to-use content ideas from a content summary, each with a hook, platform recommendation, and image generation prompt.

## What it does

Analyzes a summary file for angles worth turning into social content — controversial points, actionable advice, data, stories — then produces a structured `ideas.md` file. Each idea includes an attention-grabbing hook, a unique angle, a target platform, content category, key points, and a specific image prompt ready for Gemini or DALL-E.

## How it works

This is an instruction-based skill. Claude generates the output directly — no scripts or external APIs required. Claude reads your summary, identifies the most shareable angles, and writes a structured ideas file using the Write tool.

## Usage

```
/content-ideas path/to/summary.md
```

Example:

```
/content-ideas youtube-pipeline/my-video/summary.md
```

Running the skill with no arguments prints usage instructions and stops.

## Input format

A `summary.md` file (typically produced by `/content-summarizer`) with YAML frontmatter containing `source_title` and `source_url`. The body should include thesis, key topics, and takeaways.

## Output format

An `ideas.md` file saved to the same directory as the input. Example structure:

```markdown
---
source_title: "How AI Is Changing Software Development"
source_url: "https://youtube.com/watch?v=..."
date_generated: "2026-03-20"
type: content-ideas
---

# Content Ideas: How AI Is Changing Software Development

## Idea 1: The Skill Developers Are Ignoring in 2026
- **Hook:** Most developers are learning the wrong thing right now.
- **Angle:** Contrarian take — prompting is the new debugging
- **Platform:** X
- **Category:** Opinion
- **Key points:**
  1. AI handles syntax; humans must handle intent
  2. Prompt quality determines output quality
  3. This is measurable and learnable
- **Image concept:** Split screen — old IDE with code vs. modern AI chat with results
- **Image prompt suggestion:** "Create a split-screen illustration showing a cluttered code editor on the left and a clean AI prompt interface on the right, minimal flat design, blue tones, 1200x628"

## Quick Reference

| # | Title | Platform | Category | Image? |
|---|-------|----------|----------|--------|
| 1 | The Skill Developers Are Ignoring | X | Opinion | Yes |
```

## Pipeline context

- **Receives from:** `/content-summarizer` — a `summary.md` file
- **Feeds into:** `/social-posts` (single posts for X and LinkedIn), `/tweet-generator` (full thread generation), or `/image-generator` (to produce visuals for each idea)

Typical pipeline: `/yt-transcript` → `/content-summarizer` → `/content-ideas` → `/social-posts` or `/tweet-generator`

## Tips

- The skill enforces variety by requiring at least one opinion piece, one educational post, and one story-based post. If the summary is thin, remind Claude to push the angles rather than play it safe.
- Image prompts are written to be copy-pasted directly into an image generator. Gemini and DALL-E both work well with the format produced.
- If you want more than 10 ideas, re-run the skill and ask Claude to generate 10 additional ideas with different angles — it will not repeat the first batch.
