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

Valid step names for `--only`: `transcript`, `summary`, `obsidian`, `ideas`, `prompts`, `images`, `social`, `tweets`

### `--only` Flag Validation

After parsing the `--only` value, validate every step name against the valid list above **before** executing anything.

If any name is invalid, output this error and STOP immediately — do not run any steps:

```
Error: Invalid step name(s) in --only: "<name1>", "<name2>"

Valid step names are: transcript, summary, obsidian, ideas, prompts, images, social, tweets

Example: --only=transcript,summary,ideas
```

Replace `<name1>`, `<name2>` with the actual invalid names found in the input. Do not proceed with partial input.

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
- Wait for completion
- **Output check**: verify that `<output-dir>/transcript.md` exists and is non-empty
- If the file is missing or empty → apply the [Step Failure Protocol](#step-failure-protocol)
- **Confirmation gate** (skip if `--no-confirm`): Use the AskUserQuestion tool:
  `"Transcript extracted. Review it at <path>/transcript.md. Continue to generate summary? (y/n)"`
  - If user answers `n` → stop and show the [Pipeline Summary](#pipeline-summary)

### Step 2: Content Summary
- Run: `/content-summarizer <output-dir>/transcript.md`
- **Output check**: verify that `<output-dir>/summary.md` exists and is non-empty
- If the file is missing or empty → apply the [Step Failure Protocol](#step-failure-protocol)
- **Confirmation gate** (skip if `--no-confirm`): Use the AskUserQuestion tool:
  `"Summary generated at <path>/summary.md. Continue to create Obsidian note? (y/n)"`
  - If user answers `n` → stop and show the [Pipeline Summary](#pipeline-summary)

### Step 3: Obsidian Note (unless `--skip-obsidian`)

Before running this step, check whether the Obsidian vault is reachable:

```bash
VAULT_PATH="${OBSIDIAN_VAULT_PATH:-/home/ubuntu/Sites/projects/gp/obsidian-vault/Ved}"
if [ ! -d "$VAULT_PATH" ]; then
  echo "Warning: Obsidian vault not found at $VAULT_PATH. Skipping obsidian-note step. Set OBSIDIAN_VAULT_PATH to enable."
  # Mark step as skipped and continue — do not stop the pipeline
fi
```

- If the vault is not found: print the warning above, mark this step as skipped, and continue to Step 4. Do not stop the pipeline.
- If the vault is found: run `/obsidian-note <output-dir>/summary.md`
- **Output check**: verify the note file was created in the vault
- If creation failed → apply the [Step Failure Protocol](#step-failure-protocol)
- **Confirmation gate** (skip if `--no-confirm`): Use the AskUserQuestion tool:
  `"Obsidian note created. Continue to generate content ideas? (y/n)"`
  - If user answers `n` → stop and show the [Pipeline Summary](#pipeline-summary)

### Step 4: Content Ideas
- Run: `/content-ideas <output-dir>/summary.md`
- **Output check**: verify that `<output-dir>/ideas.md` exists and is non-empty
- If the file is missing or empty → apply the [Step Failure Protocol](#step-failure-protocol)
- **Confirmation gate** (skip if `--no-confirm`): Use the AskUserQuestion tool:
  `"Content ideas generated at <path>/ideas.md. Continue to the next step? (y/n)"`
  - If user answers `n` → stop and show the [Pipeline Summary](#pipeline-summary)

### Step 4b: Gemini Prompt Generation (when `GEMINI_API_KEY` is not set, unless `--skip-images`)

Skip this step entirely if `--skip-images` is set.

Check for `GEMINI_API_KEY`:
- **If set:** proceed directly to Step 5 (image-generator will handle image creation).
- **If not set:**
  1. Run: `Skill("gemini-prompt-generator", "<output-dir>/ideas.md")`
  2. **Output check:** verify that `<output-dir>/prompts.md` exists and is non-empty
  3. If missing or empty → apply the [Step Failure Protocol](#step-failure-protocol)
  4. **Confirmation gate** (skip if `--no-confirm`): Use the AskUserQuestion tool:
     `"Prompts saved to prompts.md. Open it, paste prompts into gemini.google.com, save images to <output-dir>/images/. Ready to continue to social posts? (y/n)"`
  5. If user answers `y` → continue to Step 6 (skip Step 5, no API key available)
  6. If user answers `n` → stop and show the [Pipeline Summary](#pipeline-summary)

### Step 5: Image Generation (unless `--skip-images`)
- Count how many image prompts are in `ideas.md` (one per idea block)
- **Confirmation gate — ALWAYS show this, even when `--no-confirm` is set** (image generation incurs API cost): Use the AskUserQuestion tool:
  `"About to generate <N> images using Gemini API (2 sizes per idea = <2N> total files). This may incur API costs. Continue? (y/n)"`
  - If user answers `n` → skip images and continue to Step 6
- Run: `/image-generator <output-dir>/ideas.md`
- **Output check**: verify that `<output-dir>/images/` directory exists and contains at least one `.png` file
- If no images were produced → apply the [Step Failure Protocol](#step-failure-protocol)
- **Confirmation gate** (skip if `--no-confirm`): Use the AskUserQuestion tool:
  `"Images generated and saved to <path>/images/. Continue to generate social posts? (y/n)"`
  - If user answers `n` → stop and show the [Pipeline Summary](#pipeline-summary)

### Step 6: Social Posts
- Run: `/social-posts <output-dir>/ideas.md`
- **Output check**: verify that `<output-dir>/social-posts.md` exists and is non-empty
- If the file is missing or empty → apply the [Step Failure Protocol](#step-failure-protocol)
- **Confirmation gate** (skip if `--no-confirm`): Use the AskUserQuestion tool:
  `"Social posts generated at <path>/social-posts.md. Continue to generate tweet threads? (y/n)"`
  - If user answers `n` → stop and show the [Pipeline Summary](#pipeline-summary)

### Step 7: Tweet Threads
- Run: `/tweet-generator <output-dir>/ideas.md`
- **Output check**: verify that `<output-dir>/tweets.md` exists and is non-empty
- If the file is missing or empty → apply the [Step Failure Protocol](#step-failure-protocol)

## Step Failure Protocol

When a step fails (skill errors out, or expected output file does not exist after the skill completes):

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
   - Skip it and proceed to the next step in the pipeline
   - Note: downstream steps that depend on this step's output may also fail; report clearly if that happens

4. If user answers `n`:
   - Stop immediately
   - Show the [Pipeline Summary](#pipeline-summary)

When `--no-confirm` is set and a step fails:
- Log the failure with the error message above
- Automatically skip to the next step (treat as if user answered `y`)
- Do not stop the pipeline

## Pipeline Summary

Show this summary whenever the pipeline stops (whether complete, user-halted, or after failures):

```
YouTube Content Pipeline — Complete!
=====================================

Output directory: <path>

Steps completed:
  [x] transcript   → transcript.md
  [x] summary      → summary.md
  [x] obsidian     → <vault-note>.md (or [skipped] / [failed])
  [x] ideas        → ideas.md
  [ ] prompts      → prompts.md (or [skipped] / [failed])
  [x] images       → images/ (or [skipped] / [failed])
  [x] social       → social-posts.md
  [x] tweets       → tweets.md

Time elapsed: ~<estimate>
=====================================
```

Use `[x]` for completed, `[ ]` for not run, `[skipped]` for intentionally skipped (flag or vault missing), and `[failed]` for steps that errored out.

## Error Handling
- Apply the [Step Failure Protocol](#step-failure-protocol) for any step that errors or produces no output
- If `--no-confirm` is set and a step fails, log the error and continue automatically
- Missing dependencies → try to install automatically via the sub-skill; report if that fails
- Track completed/failed/skipped steps throughout execution for the final summary
