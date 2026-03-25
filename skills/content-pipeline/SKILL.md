---
name: content-pipeline
description: "Unified content pipeline orchestrator. Accepts a YouTube URL or written file and produces blog, carousel, social posts, tweet threads, and more. Replaces youtube-pipeline."
argument-hint: 'content-pipeline <url-or-file-path> [--skip-blog] [--skip-images] [--skip-obsidian] [--only=ingest,summary,blog,ideas,carousel,instagram,social,tweets,images,obsidian,hashnode] [--no-confirm]'
allowed-tools: Bash, Read, Write, AskUserQuestion, Skill
---

# Content Pipeline — Unified Orchestrator

Transform any input — YouTube URL or written file — into a full suite of platform-ready content assets. This skill replaces and extends `youtube-pipeline`.

## Execution Logic

Check `$ARGUMENTS`:
- If **empty** → show usage and pipeline description below, then STOP.
- If **has arguments** → parse and execute the pipeline.

### Usage (shown when no arguments)

```
Content Pipeline — Unified Orchestrator
========================================
Usage: /content-pipeline <input> [flags]

Input:
  https://youtube.com/watch?v=...   YouTube URL → yt-transcript
  /path/to/notes.md                 Written file → text-ingestion

Flags:
  --skip-blog       Skip blog generation (use if blog.md already exists)
  --skip-images     Skip image generation (saves Gemini API cost)
  --skip-obsidian   Skip Obsidian note creation
  --only=<steps>    Run only these steps (comma-separated)
  --no-confirm      Skip all confirmation gates (except image cost warning)

Valid step names: ingest, summary, blog, ideas, carousel, instagram, social, tweets, images, obsidian, hashnode

Examples:
  /content-pipeline https://youtube.com/watch?v=dQw4w9WgXcQ
  /content-pipeline /path/to/my-notes.md
  /content-pipeline /path/to/blog.md --only=carousel,instagram,social,tweets
  /content-pipeline /path/to/notes.md --skip-images --no-confirm
========================================
```

## Parse Arguments

Extract from `$ARGUMENTS`:
- `INPUT` — first positional argument (required). A URL (starts with `http://` or `https://`) or a file path.
- `--skip-blog` → skip Step 3 (blog-generator)
- `--skip-images` → skip Step 8 (image-generator)
- `--skip-obsidian` → skip Step 9 (obsidian-note)
- `--only=<list>` → comma-separated steps to run (overrides all skip flags)
- `--no-confirm` → skip all user confirmation gates (except the image cost gate, which always shows)

Valid step names for `--only`: `ingest`, `summary`, `blog`, `ideas`, `carousel`, `instagram`, `social`, `tweets`, `images`, `obsidian`, `hashnode`

### `--only` flag validation

After parsing, validate every step name against the valid list **before** executing anything.

If any name is invalid, output this error and STOP immediately:

```
Error: Invalid step name(s) in --only: "<name1>", "<name2>"

Valid step names are: ingest, summary, blog, ideas, carousel, instagram, social, tweets, images, obsidian, hashnode

Example: --only=blog,carousel,social
```

## Detect Input Type

Inspect `INPUT`:

- If `INPUT` starts with `http://` or `https://` → **YouTube mode**. The source step will run `/yt-transcript`.
- If `INPUT` is a file path:
  - If the file ends with `.md` and its frontmatter contains `type: blog` or it has a `blog.md` filename → **Blog-only mode**. Skip to Step 4 (carousel). Set `--skip-blog` implicitly.
  - Otherwise → **Written mode**. The source step will run `/text-ingestion`.

## Determine Output Directory

- **YouTube mode**: Output directory is set by `yt-transcript` — typically `$CONTENT_PIPELINE_OUTPUT/YYYY-MM-DD-<slug>/`.
- **Written mode**: Output directory is set by `text-ingestion` — `$CONTENT_PIPELINE_OUTPUT/YYYY-MM-DD-<slug>/`.
- **Blog-only mode**: Output directory is the parent folder of the provided `blog.md` file.

After Step 1, capture the actual output directory from the skill's reported output path.

## Pipeline Overview Display

Before executing, display:

```
Content Pipeline
================
Input:   <INPUT>
Mode:    <YouTube | Written | Blog-only>
Steps:   <list of steps that will run, in order>
Output:  <output directory or "determined after step 1">
Flags:   <active flags, or "none">
================
```

## Pipeline Execution

### Step 1: Source Extraction

**YouTube mode:**
- Run: `/yt-transcript <URL>`
- Output check: verify `<output-dir>/transcript.md` exists and is non-empty
- If missing or empty → apply [Step Failure Protocol](#step-failure-protocol)
- Confirmation gate (skip if `--no-confirm`):
  `"Transcript extracted. Review it at <path>/transcript.md. Continue to generate summary? (y/n)"`

**Written mode:**
- Run: `/text-ingestion <file-path>`
- Output check: verify `<output-dir>/source.md` exists and is non-empty
- If missing or empty → apply [Step Failure Protocol](#step-failure-protocol)
- Confirmation gate (skip if `--no-confirm`):
  `"Source file normalised at <path>/source.md. Continue to generate summary? (y/n)"`

**Blog-only mode:**
- Skip this step. Set output dir to the parent of the provided file.
- Mark as `[skipped — blog-only mode]`

### Step 2: Content Summary

- Run: `/content-summarizer <output-dir>/transcript.md` (YouTube) or `/content-summarizer <output-dir>/source.md` (Written)
- Output check: verify `<output-dir>/summary.md` exists and is non-empty
- If missing or empty → apply [Step Failure Protocol](#step-failure-protocol)
- Confirmation gate (skip if `--no-confirm`):
  `"Summary generated at <path>/summary.md. Continue to generate the blog post? (y/n)"`

### Step 3: Blog Post (unless `--skip-blog`)

- Run: `/blog-generator <output-dir>/summary.md`
- Output check: verify `<output-dir>/blog.md` exists and is non-empty
- If missing or empty → apply [Step Failure Protocol](#step-failure-protocol)
- Confirmation gate (skip if `--no-confirm`):
  `"Blog post drafted at <path>/blog.md. Review it, then continue to carousel? (y/n)"`

If `--skip-blog` is set:
- Check that `<output-dir>/blog.md` already exists. If not:
  ```
  Warning: --skip-blog is set but blog.md not found at <path>. Cannot proceed without a blog post.
  ```
  Apply [Step Failure Protocol](#step-failure-protocol).
- Otherwise mark as `[skipped]` and continue.

### Step 4: Content Ideas

- Run: `/content-ideas <output-dir>/summary.md`
- Output check: verify `<output-dir>/ideas.md` exists and is non-empty
- If missing or empty → apply [Step Failure Protocol](#step-failure-protocol)
- Confirmation gate (skip if `--no-confirm`):
  `"Content ideas generated at <path>/ideas.md. Continue to carousel? (y/n)"`

### Step 5: Carousel

- Run: `/carousel-generator <output-dir>/blog.md`
- Output check: verify `<output-dir>/carousel.md` exists and is non-empty
- If missing or empty → apply [Step Failure Protocol](#step-failure-protocol)
- Confirmation gate (skip if `--no-confirm`):
  `"Carousel generated at <path>/carousel.md. Continue to Instagram caption? (y/n)"`

### Step 6: Instagram Caption

- Run: `/instagram-caption <output-dir>/blog.md`
- Output check: verify `<output-dir>/instagram.md` exists and is non-empty
- If missing or empty → apply [Step Failure Protocol](#step-failure-protocol)
- Confirmation gate (skip if `--no-confirm`):
  `"Instagram caption saved to <path>/instagram.md. Continue to X and LinkedIn posts? (y/n)"`

### Step 7: Social Posts (X + LinkedIn)

- Run: `/social-posts <output-dir>/ideas.md`

  Note: `ideas.md` is produced by Step 4. If Step 4 failed, this step will also fail — follow the Step Failure Protocol.

- Output check: verify `<output-dir>/social-posts.md` exists and contains both `## X Posts` and `## LinkedIn Posts` sections
- If missing → apply [Step Failure Protocol](#step-failure-protocol)
- Confirmation gate (skip if `--no-confirm`):
  `"X and LinkedIn posts generated at <path>/social-posts.md. Continue to tweet threads? (y/n)"`

### Step 8: Tweet Threads

- Run: `/tweet-generator <output-dir>/ideas.md`

  Note: `ideas.md` is produced by Step 4. If Step 4 failed, this step will also fail — follow the Step Failure Protocol.

- Output check: verify `<output-dir>/tweets.md` exists and is non-empty
- If missing or empty → apply [Step Failure Protocol](#step-failure-protocol)
- Confirmation gate (skip if `--no-confirm`):
  `"Tweet threads generated at <path>/tweets.md. Continue to image generation? (y/n)"`

### Step 9: Image Generation (unless `--skip-images`)

Before running:

```bash
if [ -z "$GEMINI_API_KEY" ]; then
  echo "Warning: GEMINI_API_KEY not set. Skipping image generation."
  # Mark as skipped and continue to Step 10
fi
```

If the key is missing, mark as `[skipped — no API key]` and continue.

If the key is present:
- Count image prompts in `ideas.md` (one per idea block)
- **Always show this gate — even with `--no-confirm`** (image generation incurs API cost):
  `"About to generate <N> images using Gemini API (~<2N> files). This may incur API costs. Continue? (y/n)"`
  - If `n` → mark as `[skipped — user declined]` and continue to Step 10
- Run: `/image-generator <output-dir>/ideas.md`
- Output check: verify `<output-dir>/images/` directory exists with at least one `.png` file
- If no images produced → apply [Step Failure Protocol](#step-failure-protocol)
- Confirmation gate (skip if `--no-confirm`):
  `"Images saved to <path>/images/. Continue to Obsidian note? (y/n)"`

### Step 10: Obsidian Note (unless `--skip-obsidian`)

Before running, check vault availability:

```bash
VAULT_PATH="${OBSIDIAN_VAULT_PATH:-$HOME/obsidian}"
if [ ! -d "$VAULT_PATH" ]; then
  echo "Warning: Obsidian vault not found at $VAULT_PATH. Skipping. Set OBSIDIAN_VAULT_PATH to enable."
  # Mark as skipped and continue
fi
```

If vault not found: mark as `[skipped — vault not found]` and continue.
If vault found:
- Run: `/obsidian-note <output-dir>/summary.md`
- Output check: verify the note file was created in the vault
- If creation failed → apply [Step Failure Protocol](#step-failure-protocol)
- Confirmation gate (skip if `--no-confirm`):
  `"Obsidian note created. Continue to create Hashnode draft? (y/n)"`

### Step 11: Hashnode Draft

- Run the Hashnode draft script: check if `hashnode` script or skill is available via `Bash` tool
- If Hashnode credentials (`HASHNODE_TOKEN`, `HASHNODE_PUBLICATION_ID`) are not set:
  ```
  Warning: HASHNODE_TOKEN or HASHNODE_PUBLICATION_ID not set. Skipping Hashnode draft.
  Set these environment variables to enable automatic draft creation.
  ```
  Mark as `[skipped — credentials not set]` and continue.
- If credentials are present: attempt draft creation from `<output-dir>/blog.md`
- Output check: verify the draft URL or ID is returned
- If creation failed → apply [Step Failure Protocol](#step-failure-protocol)

## Step Failure Protocol

When a step fails (skill errors, or expected output file does not exist after the skill completes):

1. Print a clear failure message:
   ```
   Error: Step <N> (<step-name>) failed.
   Reason: <describe what happened — file not found, skill error, etc.>
   Expected output: <path-to-expected-file>
   ```

2. Use the AskUserQuestion tool:
   `"Step <N> (<step-name>) failed. Continue with remaining steps? (y/n)"`

3. If user answers `y`:
   - Mark this step as **failed** in the step tracker
   - Skip it and proceed to the next step
   - Note: downstream steps that depend on this output may also fail — report clearly if that happens

4. If user answers `n`:
   - Stop immediately
   - Show the [Pipeline Summary](#pipeline-summary)

When `--no-confirm` is set and a step fails:
- Log the failure with the error message above
- Automatically skip to the next step (treat as if user answered `y`)
- Do not stop the pipeline

## Pipeline Summary

Show this summary whenever the pipeline stops (complete, user-halted, or after failures):

```
Content Pipeline — Complete!
==============================

Input:            <INPUT>
Output directory: <path>

Steps:
  [x] ingest       → <filename> (transcript.md | source.md)
  [x] summary      → summary.md
  [x] blog         → blog.md                    (or [skipped] / [failed])
  [x] ideas        → ideas.md                   (or [skipped] / [failed])
  [x] carousel     → carousel.md                (or [skipped] / [failed])
  [x] instagram    → instagram.md               (or [skipped] / [failed])
  [x] social       → social-posts.md            (or [skipped] / [failed])
  [x] tweets       → tweets.md                  (or [skipped] / [failed])
  [x] images       → images/                    (or [skipped] / [failed])
  [x] obsidian     → <vault-note>.md            (or [skipped] / [failed])
  [x] hashnode     → <draft-url>                (or [skipped] / [failed])

Time elapsed: ~<estimate>

Quick links:
  Blog:      <path>/blog.md
  Carousel:  <path>/carousel.md
  Social:    <path>/social-posts.md
  Tweets:    <path>/tweets.md
==============================
```

Use `[x]` for completed, `[ ]` for not run, `[skipped]` for intentionally skipped, and `[failed]` for steps that errored out.

## Error Handling

- Apply the [Step Failure Protocol](#step-failure-protocol) for any step that errors or produces no output
- If `--no-confirm` is set and a step fails, log the error and continue automatically
- Missing API keys → skip the affected step with a warning; do not stop the pipeline
- Vault not found → skip obsidian step with a warning; do not stop the pipeline
- Track completed/failed/skipped steps throughout for the final summary
