---
name: youtube-pipeline
description: "Full YouTube content pipeline: URL → transcript → summary → Obsidian note → content ideas → images → social posts → tweets. Orchestrates all pipeline skills with user gates."
argument-hint: 'youtube-pipeline https://youtube.com/watch?v=VIDEO_ID [--skip-images] [--skip-obsidian] [--only=transcript,summary] [--no-confirm]'
allowed-tools: Bash, Read, Write, AskUserQuestion, Skill
---

# YouTube Content Pipeline — Orchestrator

Chain all pipeline skills to transform a YouTube URL into complete content assets.

## Execution Logic

Check `$ARGUMENTS`:
- If **empty** → respond with usage info and full pipeline description, then STOP.
- If **has arguments** → parse and execute the pipeline.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `URL` — YouTube URL (required, first positional argument)
- `--skip-images` → skip image generation step
- `--skip-obsidian` → skip Obsidian note creation
- `--only=<list>` → comma-separated list of steps to run (e.g., `--only=transcript,summary`)
- `--no-confirm` → skip user confirmation gates between steps

Valid step names for `--only`: `transcript`, `summary`, `obsidian`, `ideas`, `images`, `social`, `tweets`

## Pipeline Execution

Display pipeline overview:
```
YouTube Content Pipeline
========================
URL: <url>
Steps: <list of steps that will run>
Output: <output directory>
========================
```

### Step 1: Transcript Extraction
- Run: `/yt-transcript <URL>`
- Wait for completion, verify `transcript.md` was created
- If `--no-confirm` is NOT set, ask user: "Transcript extracted. Continue to summary? (Y/n)"

### Step 2: Content Summary
- Run: `/content-summarizer <output-dir>/transcript.md`
- Verify `summary.md` was created
- Gate: "Summary generated. Continue to Obsidian note? (Y/n)"

### Step 3: Obsidian Note (unless `--skip-obsidian`)
- Run: `/obsidian-note <output-dir>/summary.md`
- Gate: "Obsidian note created. Continue to content ideas? (Y/n)"

### Step 4: Content Ideas
- Run: `/content-ideas <output-dir>/summary.md`
- Verify `ideas.md` was created
- Gate: "Ideas generated. Continue to image generation? (Y/n)"

### Step 5: Image Generation (unless `--skip-images`)
- Check if `GEMINI_API_KEY` is available
- If not available: warn and skip, continue to next step
- Run: `/image-generator <output-dir>/ideas.md`
- Gate: "Images generated. Continue to social posts? (Y/n)"

### Step 6: Social Posts
- Run: `/social-posts <output-dir>/ideas.md`
- Gate: "Social posts generated. Continue to tweet threads? (Y/n)"

### Step 7: Tweet Threads
- Run: `/tweet-generator <output-dir>/ideas.md`

### Pipeline Complete
```
YouTube Content Pipeline — Complete!
=====================================

Output directory: <path>

Files generated:
  transcript.md — Full video transcript
  summary.md — Structured content summary
  <vault-note>.md — Obsidian vault note (or skipped)
  ideas.md — 5-10 content ideas with image concepts
  images/ — Marketing-ready images (or skipped)
  social-posts.md — X + LinkedIn posts
  tweets.md — Tweet threads

Time elapsed: ~<estimate>
=====================================
```

## Error Handling
- If any step fails, report the error and ask: "Step <N> failed. Skip and continue, or stop?"
- If `--no-confirm` is set and a step fails, log the error and continue
- Missing dependencies → try to install automatically, report if that fails
- Track which steps completed for the final report
