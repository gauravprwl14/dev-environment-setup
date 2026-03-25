# Gemini Prompt Generator — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `gemini-prompt-generator` Claude Code skill that reads `ideas.md` and writes `prompts.md` with 3 Gemini-optimised image prompt variants per idea — no API key required.

**Architecture:** Pure LLM-native skill (no backend scripts). Claude reads `ideas.md`, generates prompts in memory following the spec's prompt anatomy rules, and writes `prompts.md`. Also updates `youtube-pipeline` to route to this skill when `GEMINI_API_KEY` is absent, and adds a next-step pointer in `content-ideas`.

**Tech Stack:** Markdown, Claude Code skill frontmatter (YAML), JSON (plugin.json). No Python, no Node.js, no external APIs.

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `skills/gemini-prompt-generator/SKILL.md` | Execution instructions for Claude — the skill itself |
| Create | `skills/gemini-prompt-generator/README.md` | Human docs: what it does, how to use it, manual workflow |
| Create | `skills/gemini-prompt-generator/.claude-plugin/plugin.json` | Skill metadata for the plugin system |
| Create | `tests/fixtures/sample-ideas.md` | Test fixture: realistic ideas.md with 3 ideas, used to smoke-test the skill |
| Modify | `skills/.claude-plugin/plugin.json` | Register `"./gemini-prompt-generator"` in the skills array |
| Modify | `skills/content-ideas/SKILL.md` | Add `/gemini-prompt-generator` to the Next steps report block |
| Modify | `skills/youtube-pipeline/SKILL.md` | Insert Step 4b, remove Step 5 no-key guard, update step names list in 2 places, add `prompts` row to Pipeline Summary |

---

## Task 1: Create Test Fixture

**Files:**
- Create: `tests/fixtures/sample-ideas.md`

This fixture is used in Task 8 to verify the skill works correctly. Create it first so the expected output is clear.

- [ ] **Step 1: Create the fixtures directory and sample ideas file**

Create `tests/fixtures/sample-ideas.md` with exactly this content:

```markdown
---
source_title: "How AI is Changing Software Development"
source_url: "https://youtube.com/watch?v=example123"
date_generated: "2026-03-20"
type: content-ideas
---

# Content Ideas: How AI is Changing Software Development

## Idea 1: The Death of the Junior Developer?

- **Hook:** AI tools wrote 40% of new code at GitHub last year. What does that mean for people just starting out?
- **Angle:** Contrarian take — AI doesn't kill junior roles, it changes what juniors need to learn first
- **Platform:** X
- **Category:** Opinion
- **Key points:**
  1. AI handles boilerplate, so fundamentals matter more not less
  2. Debugging and systems thinking become the entry-level skill
  3. Junior developers who use AI well outperform seniors who don't
- **Image concept:** Split screen showing a human developer and an AI side by side at desks, collaborative not competitive
- **Image prompt suggestion:** Create a cinematic split-screen image showing a focused junior developer at a modern workstation on the left and a glowing AI interface on the right, both working on the same codebase, warm desk lamp lighting on the human side, cool blue glow on the AI side, professional editorial photography style, 16:9

## Idea 2: Ship Your First AI Feature in a Weekend

- **Hook:** You don't need a PhD. You need a weekend and an API key.
- **Angle:** Practical how-to showing the exact steps to build and deploy a real AI feature
- **Platform:** LinkedIn
- **Category:** How-To
- **Key points:**
  1. Pick one boring workflow and automate it with Claude API
  2. Wrap it in a simple Node.js or Python script
  3. Deploy to Vercel or Railway in under 10 minutes
- **Image concept:** A developer's desk at 2am with a laptop showing a deployed app, coffee cup, notebook with sketches, green terminal output
- **Image prompt suggestion:** Create a digital illustration of a developer's desk late at night, glowing laptop screen showing a successful deployment with green checkmarks, steaming coffee mug, handwritten notes scattered around, warm tungsten lamp light, cosy productive atmosphere, bold colour palette, 4:5

## Idea 3: Why Most AI Demos Fail in Production

- **Hook:** That AI prototype that wowed everyone in the demo? It broke on day one. Here's why.
- **Angle:** Technical analysis of the gap between demo-quality and production-quality AI integrations
- **Platform:** Both
- **Category:** Educational
- **Key points:**
  1. Prompt engineering that works in testing fails on real user input
  2. Error handling and fallbacks are always an afterthought
  3. Cost at scale was never modelled in the prototype phase
- **Image concept:** A polished demo screen cracking to reveal messy reality underneath, like a stage set breaking apart
- **Image prompt suggestion:** Create a clean minimalist graphic showing a pristine presentation slide on the left transforming into chaotic broken code and error messages on the right, flat design aesthetic, red and white colour palette, professional infographic style, 1:1
```

- [ ] **Step 2: Verify the fixture has the required structure**

Confirm by reading the file that it contains:
- Exactly 3 `## Idea N:` headings
- All 3 have `**Image prompt suggestion:**` fields
- Frontmatter block is present

- [ ] **Step 3: Commit the test fixture**

```bash
git add tests/fixtures/sample-ideas.md
git commit -m "test(fixtures): add sample ideas.md for gemini-prompt-generator smoke test"
```

---

## Task 2: Create SKILL.md

**Files:**
- Create: `skills/gemini-prompt-generator/SKILL.md`

This is the core of the skill — the instructions Claude follows when invoked as `/gemini-prompt-generator`.

- [ ] **Step 1: Create the SKILL.md file**

Create `skills/gemini-prompt-generator/SKILL.md` with this exact content:

```markdown
---
name: gemini-prompt-generator
description: "Generate 3 Gemini-optimised image prompt variants per content idea. Reads ideas.md, writes prompts.md. No API key required — prompts are for manual use in Gemini / Nano Banana Pro."
argument-hint: 'gemini-prompt-generator path/to/ideas.md'
allowed-tools: Read, Write
---

# Gemini Prompt Generator

Generate 3 Gemini-optimised image prompt variants per content idea — Cinematic, Illustrative, and Minimal/Graphic — ready to paste into Gemini or Nano Banana Pro.

## Execution Logic

Check `$ARGUMENTS`:
- If **empty** → respond with the usage block below and STOP:

```
Gemini Prompt Generator loaded.
Usage: /gemini-prompt-generator path/to/ideas.md

Reads ideas.md (produced by /content-ideas) and writes prompts.md with 3
Gemini-optimised image prompt variants per idea. No API key required.
```

- If **has arguments** → treat as path to `ideas.md` and execute below.

## Task Execution

### Step 1 — Read and parse `ideas.md`

Use the Read tool to read the file at `$ARGUMENTS`.

**If file does not exist:** print `Error: File not found: <path>` and STOP.

Parse each idea section by finding headings matching `## Idea N: <Title>` (N = any number). From each section, extract:
- **Title** — from the heading
- **Angle** — from the `**Angle:**` field
- **Image prompt** — from the `**Image prompt suggestion:**` field. Also accept close variants: `**Image Prompt:**`, `**Image prompt:**`, `**Image Prompt Suggestion:**`.

**If no `## Idea N:` headings are found:** print the following and STOP:
```
Error: No ideas found in <path>.
Expected headings like: ## Idea 1: Title
Run /content-ideas first to generate ideas.md.
```

**If some ideas are missing the image prompt field:** print a warning and skip that idea, continue with the rest:
```
Warning: Idea N ("<Title>") has no image prompt field — skipping.
```

### Step 2 — Generate 3 prompt variants per idea

For each parsed idea, generate three distinct Gemini-optimised prompt variants. Apply the Prompt Anatomy rules below. The three variants MUST be visually and stylistically different — no overlapping medium, mood, or aesthetic.

#### Variant A — Cinematic
Photorealistic, dramatic lighting, film/documentary aesthetic.
- Style keywords: `cinematic photography`, `35mm film`, `documentary photography`, `editorial photography`
- Lighting: ONE specific style — e.g. `golden hour backlight`, `dramatic chiaroscuro`, `volumetric rays`, `soft diffused window light`
- Aspect ratio hint: `16:9`
- Best for: YouTube thumbnails, blog headers

#### Variant B — Illustrative
Stylised digital art, bold palette, graphic design aesthetic.
- Style keywords: `digital illustration`, `concept art`, `bold graphic style`, `vibrant colour palette`
- Lighting: atmospheric — e.g. `glowing ambient light`, `cel-shaded`, `flat stylised lighting`
- Aspect ratio hint: `4:5`
- Best for: Instagram, social posts, Hashnode cover images

#### Variant C — Minimal/Graphic
Clean, professional, text-safe composition.
- Style keywords: `minimalist design`, `studio photography`, `flat design`, `clean white background`, `3D render`
- Lighting: clean — e.g. `soft studio lighting`, `even diffused light`, `bright flat lighting`
- Aspect ratio hint: `1:1`
- Best for: LinkedIn, professional content

#### Prompt Anatomy (apply to every variant, in this order)
1. **Subject** — specific to the idea's angle, not generic stock imagery
2. **Environment/Context** — setting and surrounding elements
3. **Lighting** — one named lighting style (never "good lighting" or "nice light")
4. **Mood/Atmosphere** — the emotional tone
5. **Style/Medium** — art style, medium, or aesthetic movement
6. **Quality keywords** — use from: `highly detailed`, `sharp focus`, `professional quality`, `vibrant`, `8K resolution`, `photorealistic`

#### Banned terms — NEVER use in any prompt
`beautiful`, `amazing`, `nice`, `good`, `wonderful`, `stunning`, `good lighting`, `nice light`
Replace with specific descriptors.

#### Prompt length
2–4 sentences per variant. Detailed enough to guide the model, short enough to parse cleanly.

### Step 3 — Write `prompts.md`

Determine the output path: same directory as `$ARGUMENTS`, named `prompts.md`.

Use the Write tool to save the file. Overwrite without confirmation if it already exists (prompts are regeneratable).

**If the write fails:** print `Error: Could not write to <path>` and STOP.

Output format:

```markdown
# Gemini Image Prompts
Generated: YYYY-MM-DD | Source: ideas.md

---

## Idea 1: [Title]

**Angle:** [angle from ideas.md]

### Variant A — Cinematic
> [2-4 sentence Gemini-optimised prompt]

- Aspect ratio: 16:9
- Best for: YouTube thumbnail, blog header

### Variant B — Illustrative
> [2-4 sentence Gemini-optimised prompt]

- Aspect ratio: 4:5
- Best for: Instagram, social posts, Hashnode cover

### Variant C — Minimal/Graphic
> [2-4 sentence Gemini-optimised prompt]

- Aspect ratio: 1:1
- Best for: LinkedIn, professional content

---

## Idea 2: [Title]
[same structure]

---

_Paste any prompt into gemini.google.com or Nano Banana Pro to generate the image._
_To automate: `/image-generator path/to/ideas.md` (requires GEMINI_API_KEY)_
```

### Step 4 — Report

Print:
```
Generated prompts for N ideas (N×3 = M variants total)
Saved: path/to/prompts.md

Next steps:
- Open prompts.md and paste any prompt into gemini.google.com or Nano Banana Pro
- /image-generator path/to/ideas.md  — skip manual step, generate via API instead
```

## Error Handling

| Situation | Response |
|-----------|----------|
| Empty `$ARGUMENTS` | Print usage block and STOP |
| File not found | `Error: File not found: <path>` and STOP |
| No ideas parsed | `Error: No ideas found in <path>. Expected headings like: ## Idea 1: Title` and STOP |
| Idea missing image prompt | `Warning: Idea N ("<Title>") has no image prompt field — skipping.` then continue |
| Write fails | `Error: Could not write to <path>` and STOP |

## Quality Rules

1. No banned terms in any prompt (`beautiful`, `amazing`, `nice`, `good lighting`, etc.)
2. Each variant uses a different style, medium, and mood — no overlap
3. Lighting must be a named style in every variant
4. Subject must derive from the idea's angle, not be generic
5. Prompt length: 2–4 sentences per variant
```

- [ ] **Step 2: Verify frontmatter is valid**

Read the file back and confirm the frontmatter block (lines 1–6) contains exactly:
- `name: gemini-prompt-generator`
- `description: "..."`
- `argument-hint: 'gemini-prompt-generator path/to/ideas.md'`
- `allowed-tools: Read, Write`

- [ ] **Step 3: Commit**

```bash
git add skills/gemini-prompt-generator/SKILL.md
git commit -m "feat(skills/gemini-prompt-generator): add SKILL.md — LLM-native prompt generator"
```

---

## Task 3: Create plugin.json and README.md

**Files:**
- Create: `skills/gemini-prompt-generator/.claude-plugin/plugin.json`
- Create: `skills/gemini-prompt-generator/README.md`

- [ ] **Step 1: Create plugin.json**

Create `skills/gemini-prompt-generator/.claude-plugin/plugin.json`:

```json
{
  "name": "gemini-prompt-generator",
  "description": "Generate 3 Gemini-optimised image prompt variants per content idea. Reads ideas.md, writes prompts.md. No API key required.",
  "version": "1.0.0",
  "user-invocable": true
}
```

- [ ] **Step 2: Create README.md**

Create `skills/gemini-prompt-generator/README.md`:

```markdown
# gemini-prompt-generator

Generate 3 Gemini-optimised image prompt variants per content idea — ready to paste into [Gemini](https://gemini.google.com) or Nano Banana Pro. No API key required.

## What it does

Reads `ideas.md` (produced by `/content-ideas`) and writes `prompts.md` with three prompt variants per idea:

| Variant | Style | Aspect Ratio | Best for |
|---------|-------|-------------|---------|
| Cinematic | Photorealistic, dramatic lighting | 16:9 | YouTube thumbnails, blog headers |
| Illustrative | Digital art, bold palette | 4:5 | Instagram, social posts, Hashnode cover |
| Minimal/Graphic | Clean, professional, text-safe | 1:1 | LinkedIn, professional content |

## How it works

This is an **instruction-based skill** — Claude generates the prompts directly. No scripts, no external APIs, no billing required. Claude reads your content ideas and writes optimised Gemini prompts tailored to each idea's angle and hook.

## Usage

```
/gemini-prompt-generator path/to/ideas.md
```

The `ideas.md` must be generated by `/content-ideas` first. The output `prompts.md` is saved in the same directory.

## Example

```
/content-ideas output/2026-03-20/summary.md
/gemini-prompt-generator output/2026-03-20/ideas.md
```

Then open `output/2026-03-20/prompts.md`, copy any prompt, and paste it into:
- **gemini.google.com** — click "Generate image" or use the image generation interface
- **Nano Banana Pro** (`gemini-3-pro-image-preview`) — paste as the image generation prompt

## Output format

```
prompts.md
├── Idea 1: [Title]
│   ├── Variant A — Cinematic (16:9)
│   ├── Variant B — Illustrative (4:5)
│   └── Variant C — Minimal/Graphic (1:1)
├── Idea 2: [Title]
│   └── ...
└── ...
```

## Pipeline position

```
/content-ideas → ideas.md → /gemini-prompt-generator → prompts.md → [manual Gemini] → images/
                                                                   ↘ /image-generator → images/
```

## Prerequisites

- `ideas.md` must exist (run `/content-ideas` first)
- No API key, no Python, no Node.js required

## Automated alternative

If you have a Gemini API key with billing enabled, `/image-generator path/to/ideas.md` generates images automatically without the manual step.
```

- [ ] **Step 3: Commit**

```bash
git add skills/gemini-prompt-generator/.claude-plugin/plugin.json skills/gemini-prompt-generator/README.md
git commit -m "feat(skills/gemini-prompt-generator): add plugin.json and README"
```

---

## Task 4: Register in Plugin Bundle

**Files:**
- Modify: `skills/.claude-plugin/plugin.json`

- [ ] **Step 1: Read the current plugin.json**

Read `skills/.claude-plugin/plugin.json` to see the current `skills` array.

- [ ] **Step 2: Add the new skill to the array**

Add `"./gemini-prompt-generator"` to the `skills` array, after `"./content-ideas"` (keep alphabetical/logical order). The array should look like:

```json
"skills": [
  "./yt-transcript",
  "./content-summarizer",
  "./obsidian-note",
  "./obsidian-vault-guide",
  "./content-ideas",
  "./gemini-prompt-generator",
  "./image-generator",
  "./social-posts",
  "./tweet-generator",
  "./youtube-pipeline",
  "./skill-scaffold",
  "./hashnode"
]
```

- [ ] **Step 3: Validate JSON**

Run:
```bash
python3 -m json.tool skills/.claude-plugin/plugin.json > /dev/null && echo "JSON valid"
```
Expected: `JSON valid`

- [ ] **Step 4: Commit**

```bash
git add skills/.claude-plugin/plugin.json
git commit -m "feat(skills): register gemini-prompt-generator in plugin bundle"
```

---

## Task 5: Update content-ideas Next Steps

**Files:**
- Modify: `skills/content-ideas/SKILL.md` (lines 77–81)

- [ ] **Step 1: Read the current Next steps block**

Read `skills/content-ideas/SKILL.md` and find the "Report results" section (around line 71–81).

- [ ] **Step 2: Add gemini-prompt-generator to the Next steps**

The current block:
```
Next steps:
- `/social-posts <path>/ideas.md` — Generate ready-to-post social content
- `/tweet-generator <path>/ideas.md` — Generate tweet threads
- `/image-generator <path>/ideas.md` — Generate images for each idea
```

Replace with:
```
Next steps:
- `/gemini-prompt-generator <path>/ideas.md` — Generate Gemini image prompts (no API key needed)
- `/image-generator <path>/ideas.md` — Generate images automatically via API
- `/social-posts <path>/ideas.md` — Generate ready-to-post social content
- `/tweet-generator <path>/ideas.md` — Generate tweet threads
```

- [ ] **Step 3: Commit**

```bash
git add skills/content-ideas/SKILL.md
git commit -m "feat(skills/content-ideas): add gemini-prompt-generator to next steps"
```

---

## Task 6: Update youtube-pipeline

**Files:**
- Modify: `skills/youtube-pipeline/SKILL.md`

This is the most involved modification — 5 separate changes to the file. Read it fully before editing.

- [ ] **Step 1: Read youtube-pipeline/SKILL.md in full**

Read `skills/youtube-pipeline/SKILL.md` and note the exact line numbers of:
- The `--only` valid step names line (currently: `transcript, summary, obsidian, ideas, images, social, tweets`)
- The error message block that lists valid step names (the `--only` flag validation error)
- The end of Step 4 / start of Step 5 (where Step 4b will be inserted)
- Step 5's no-key guard line (`Check if GEMINI_API_KEY is available; if not: warn and skip`)
- The Pipeline Summary steps table (the `[x] transcript → transcript.md` block)

- [ ] **Step 2: Update the `--only` valid step names — first location**

Find the line:
```
Valid step names for `--only`: `transcript`, `summary`, `obsidian`, `ideas`, `images`, `social`, `tweets`
```

Replace with:
```
Valid step names for `--only`: `transcript`, `summary`, `obsidian`, `ideas`, `prompts`, `images`, `social`, `tweets`
```

- [ ] **Step 3: Update the `--only` error message — second location**

Find the error message block that reads:
```
Valid step names are: transcript, summary, obsidian, ideas, images, social, tweets
```

Replace with:
```
Valid step names are: transcript, summary, obsidian, ideas, prompts, images, social, tweets
```

- [ ] **Step 4: Insert Step 4b after Step 4**

Find the end of Step 4 (after the `ideas.md` confirmation gate block). Insert this new step immediately after Step 4's closing lines and before `### Step 5`:

```markdown
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
```

- [ ] **Step 5: Remove Step 5's no-key guard**

Find this line in Step 5:
```
- Check if `GEMINI_API_KEY` is available; if not: warn and skip, continue to Step 6
```

Remove that line entirely. Step 5 now assumes `GEMINI_API_KEY` is available (Step 4b handles the no-key path and either provides prompts for manual use or routes past Step 5).

- [ ] **Step 6: Add `prompts` row to Pipeline Summary**

Find the Pipeline Summary steps table:
```
  [x] ideas        → ideas.md
  [x] images       → images/ (or [skipped] / [failed])
```

Insert a `prompts` row between `ideas` and `images`:
```
  [x] ideas        → ideas.md
  [ ] prompts      → prompts.md (or [skipped] / [failed])
  [x] images       → images/ (or [skipped] / [failed])
```

- [ ] **Step 7: Verify the file reads correctly end-to-end**

Read the full `youtube-pipeline/SKILL.md` and confirm:
- `prompts` appears in both valid step names locations
- Step 4b block is present between Step 4 and Step 5
- Step 5 no longer contains `if not set: warn and skip`
- Pipeline Summary has a `prompts` row

- [ ] **Step 8: Commit**

```bash
git add skills/youtube-pipeline/SKILL.md
git commit -m "feat(skills/youtube-pipeline): add Step 4b gemini-prompt-generator fallback when no API key"
```

---

## Task 7: Smoke Test the Skill

**Files:**
- Read: `tests/fixtures/sample-ideas.md`
- Verify: `tests/fixtures/prompts.md` (generated by the skill)

This tests the full skill using the fixture created in Task 1. The skill is LLM-native so the "test" is a functional verification of the output.

- [ ] **Step 1: Run the skill against the test fixture**

In a Claude Code session, invoke:
```
/gemini-prompt-generator tests/fixtures/sample-ideas.md
```

- [ ] **Step 2: Verify prompts.md was created**

```bash
ls -la tests/fixtures/prompts.md
```
Expected: file exists, non-empty (should be several hundred lines)

- [ ] **Step 3: Verify structure — 3 ideas × 3 variants = 9 prompts**

```bash
grep -c "### Variant" tests/fixtures/prompts.md
```
Expected output: `9`

```bash
grep -c "## Idea" tests/fixtures/prompts.md
```
Expected output: `3`

- [ ] **Step 4: Verify no banned terms appear**

```bash
grep -iE "\b(beautiful|amazing|wonderful|stunning|good lighting|nice light)\b" tests/fixtures/prompts.md
```
Expected: no output (empty — banned terms absent)

- [ ] **Step 5: Verify aspect ratio hints are present**

```bash
grep -c "Aspect ratio:" tests/fixtures/prompts.md
```
Expected: `9` (one per variant)

- [ ] **Step 6: Verify all three variant types appear**

```bash
grep "Variant A — Cinematic" tests/fixtures/prompts.md | wc -l
grep "Variant B — Illustrative" tests/fixtures/prompts.md | wc -l
grep "Variant C — Minimal/Graphic" tests/fixtures/prompts.md | wc -l
```
Expected: `3` for each (one per idea)

- [ ] **Step 7: Verify the footer links are present**

```bash
grep "gemini.google.com" tests/fixtures/prompts.md
grep "image-generator" tests/fixtures/prompts.md
```
Expected: both lines present

- [ ] **Step 8: Test the empty-arguments guard**

In a Claude Code session, invoke:
```
/gemini-prompt-generator
```
Expected: prints usage block, does NOT create any files, stops.

- [ ] **Step 9: Test the file-not-found guard**

In a Claude Code session, invoke:
```
/gemini-prompt-generator tests/fixtures/nonexistent.md
```
Expected: prints `Error: File not found: tests/fixtures/nonexistent.md` and stops.

- [ ] **Step 10: Commit the generated test output**

```bash
git add tests/fixtures/prompts.md
git commit -m "test(fixtures): add smoke test output for gemini-prompt-generator"
```

---

## Task 8: Final Integration Verification

- [ ] **Step 1: Verify plugin bundle includes the new skill**

```bash
python3 -c "
import json
with open('skills/.claude-plugin/plugin.json') as f:
    d = json.load(f)
skills = d['skills']
print('Skills registered:', len(skills))
print('gemini-prompt-generator present:', './gemini-prompt-generator' in skills)
"
```
Expected:
```
Skills registered: 12
gemini-prompt-generator present: True
```

- [ ] **Step 2: Verify content-ideas next steps updated**

```bash
grep "gemini-prompt-generator" skills/content-ideas/SKILL.md
```
Expected: one line referencing `/gemini-prompt-generator`

- [ ] **Step 3: Verify youtube-pipeline has both valid step name locations updated**

```bash
grep -n "prompts" skills/youtube-pipeline/SKILL.md | head -10
```
Expected: `prompts` appears in at least 4 places:
- valid step names line
- error message block
- Step 4b heading
- Pipeline Summary table

- [ ] **Step 4: Verify Step 5 no-key guard is gone**

```bash
grep "if not set: warn and skip" skills/youtube-pipeline/SKILL.md
```
Expected: no output (line removed)

- [ ] **Step 5: Final commit with full summary**

```bash
git add -A
git commit -m "$(cat <<'EOF'
feat(skills): add gemini-prompt-generator skill

New LLM-native skill generates 3 Gemini-optimised image prompt variants
(Cinematic, Illustrative, Minimal/Graphic) per idea from ideas.md.
No API key required — prompts for manual use in Gemini / Nano Banana Pro.

- skills/gemini-prompt-generator/SKILL.md — core skill execution logic
- skills/gemini-prompt-generator/README.md — human docs and usage guide
- skills/gemini-prompt-generator/.claude-plugin/plugin.json — skill metadata
- skills/.claude-plugin/plugin.json — registered in plugin bundle
- skills/content-ideas/SKILL.md — added gemini-prompt-generator to next steps
- skills/youtube-pipeline/SKILL.md — Step 4b routes to this skill when no API key
- tests/fixtures/ — smoke test fixture and verified output

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```
