# Design: `gemini-prompt-generator` Skill

**Date:** 2026-03-20
**Author:** Gaurav (Ved)
**Status:** Approved for implementation

---

## Problem Statement

The existing `image-generator` skill calls the Gemini API directly and requires billing to be enabled on the Google AI project. Users with Gemini Pro access may prefer to generate images manually through the Gemini web interface or Nano Banana Pro, but currently have no way to generate high-quality, Gemini-optimised prompts from their content ideas automatically.

The `content-ideas` skill produces a raw image prompt suggestion per idea. These raw suggestions are not optimised for Gemini's image model prompt dialect — they lack style references, lighting descriptors, aspect ratio hints, mood keywords, and the quality terms that consistently produce better results from Gemini image generation.

---

## Goals

- Read `ideas.md` produced by `content-ideas`
- For each idea, generate **3 Gemini-optimised prompt variants** (Cinematic, Illustrative, Minimal/Graphic)
- Save all prompts to `prompts.md` in the same directory as `ideas.md`
- Require no API key, no external scripts — pure LLM-native skill
- Fit cleanly into the `youtube-pipeline` between `content-ideas` and `image-generator`

## Non-Goals

- Does not call the Gemini API (that is `image-generator`'s job)
- Does not support other image generation tools (Midjourney, SD, DALL-E) — Gemini-only
- Does not generate images — only prompts

---

## SKILL.md Frontmatter

The `SKILL.md` file must open with this exact frontmatter block (required for Claude Code to invoke the skill):

```
---
name: gemini-prompt-generator
description: "Generate 3 Gemini-optimised image prompt variants per content idea. Reads ideas.md, writes prompts.md. No API key required — prompts are for manual use in Gemini / Nano Banana Pro."
argument-hint: 'gemini-prompt-generator path/to/ideas.md'
allowed-tools: Read, Write
---
```

---

## Skill Specification

### Name
`gemini-prompt-generator`

### Type
Instruction-based (LLM-native) — Claude generates prompts directly, no backend scripts required.

### Invocation
```
/gemini-prompt-generator path/to/ideas.md
```

### Arguments
| Argument | Required | Description |
|----------|----------|-------------|
| `path/to/ideas.md` | Yes | Path to the `ideas.md` file produced by `content-ideas` |

---

## Execution Logic

### Step 1 — Argument check
If `$ARGUMENTS` is empty: print the following and stop:
```
Gemini Prompt Generator loaded.
Usage: /gemini-prompt-generator path/to/ideas.md

Reads ideas.md (from /content-ideas) and writes prompts.md with 3
Gemini-optimised image prompt variants per idea.
```

### Step 2 — Read and parse `ideas.md`

Use the Read tool to read the file at `$ARGUMENTS`.

**If the file does not exist:** print `Error: File not found: <path>` and stop.

Parse each idea section by looking for headings matching `## Idea N: <Title>` (where N is a number). From each idea section, extract:
- **Title** — from the heading
- **Angle/Hook** — from the `**Hook:**` or `**Angle:**` field
- **Image prompt** — from the `**Image prompt suggestion:**` field, and close variants like `**Image Prompt:**` or `**Image prompt:**`

**If no ideas are found** (no `## Idea N:` headings match): print the following and stop:
```
Error: No ideas found in <path>.
Expected headings like: ## Idea 1: Title
```

**If some ideas are missing the image prompt field:** skip them with a warning printed to output, continue processing the others:
```
Warning: Idea N ("<Title>") has no image prompt field — skipping.
```

### Step 3 — Generate 3 variants per idea

For each parsed idea, produce three Gemini-optimised prompt variants. Apply the prompt anatomy below to each. The three variants must be visually and stylistically distinct — no overlapping aesthetic, medium, or mood.

**Variant A — Cinematic**
Photorealistic, dramatic lighting, film/documentary aesthetic. Best for YouTube thumbnails and blog headers.
- Style: `cinematic photography`, `35mm film`, `documentary photography`
- Lighting: specific — e.g. `golden hour`, `dramatic side lighting`, `volumetric light rays`, `chiaroscuro`
- Aspect ratio hint: `16:9`

**Variant B — Illustrative**
Stylised digital art, bold colour palette, graphic design sensibility. Best for social posts and Hashnode cover images.
- Style: `digital illustration`, `vibrant colour palette`, `bold graphic style`, `concept art`
- Lighting: atmospheric — e.g. `glowing ambient light`, `flat stylised lighting`, `cel-shaded`
- Aspect ratio hint: `4:5`

**Variant C — Minimal/Graphic**
Clean, professional, text-safe composition. Flat design, studio render, or product photography. Best for LinkedIn and professional content.
- Style: `minimalist design`, `studio photography`, `clean white background`, `flat design`, or `3D render`
- Lighting: clean — e.g. `soft studio lighting`, `even diffused light`
- Aspect ratio hint: `1:1`

**Prompt anatomy for every variant (in this order):**
1. **Subject** — derived from the idea's image prompt and angle, specific not generic
2. **Environment/Context** — setting, what surrounds the subject
3. **Lighting** — one specific lighting style (no generic terms like "good lighting")
4. **Mood/Atmosphere** — emotional tone
5. **Style/Medium reference** — art style, medium, or aesthetic movement
6. **Quality keywords** — from the approved list: `highly detailed`, `sharp focus`, `professional quality`, `vibrant`, `8K resolution`, `photorealistic`

**Banned terms (never use in any prompt):**
- `beautiful`, `amazing`, `nice`, `good`, `wonderful`, `stunning` — replace with specific descriptors
- `good lighting` — replace with a named lighting style

**Length:** 2–4 sentences per variant. Detailed enough to guide the model, short enough to parse cleanly.

### Step 4 — Write `prompts.md`

Determine the output path: same directory as the input `ideas.md`, named `prompts.md`.

Use the Write tool to save the file. Overwrite without confirmation if the file already exists (prompts are always regeneratable from `ideas.md`).

**If the write fails** (permission error or disk issue): print `Error: Could not write to <path>: <reason>` and stop.

### Step 5 — Report

Print the following summary:
```
Generated prompts for N ideas (N×3 = M variants total)
Saved: path/to/prompts.md

Next steps:
- Open prompts.md and paste any prompt into gemini.google.com or Nano Banana Pro
- /image-generator path/to/ideas.md  — skip manual step, generate via API instead
```

---

## Output Format — `prompts.md`

```markdown
# Gemini Image Prompts
Generated: YYYY-MM-DD | Source: ideas.md

---

## Idea 1: [Title]

**Angle:** [one-line angle/hook from ideas.md]

### Variant A — Cinematic
> [full Gemini-optimised prompt, 2-4 sentences]

- Aspect ratio: 16:9
- Best for: YouTube thumbnail, blog header

### Variant B — Illustrative
> [full Gemini-optimised prompt, 2-4 sentences]

- Aspect ratio: 4:5
- Best for: Instagram, social posts, Hashnode cover

### Variant C — Minimal/Graphic
> [full Gemini-optimised prompt, 2-4 sentences]

- Aspect ratio: 1:1
- Best for: LinkedIn, profile-safe content

---

## Idea 2: [Title]
[same structure repeats]

---

_Paste any prompt directly into gemini.google.com or Nano Banana Pro to generate the image manually._
_To automate: `/image-generator path/to/ideas.md` (requires GEMINI_API_KEY)_
```

---

## Error Handling

| Situation | Response |
|-----------|----------|
| Empty `$ARGUMENTS` | Print usage block and stop |
| File path does not exist | `Error: File not found: <path>` and stop |
| File has no `## Idea N:` headings | `Error: No ideas found in <path>. Expected headings like: ## Idea 1: Title` and stop |
| An idea has no image prompt field | `Warning: Idea N ("<Title>") has no image prompt field — skipping.` then continue |
| Write to `prompts.md` fails | `Error: Could not write to <path>: <reason>` and stop |

---

## Quality Rules

The skill must enforce these constraints on every generated prompt:

1. **No generic filler** — `beautiful`, `amazing`, `nice` are banned. Use specific descriptors.
2. **Specific lighting only** — never `good lighting`. Must use a named style: `golden hour`, `rim lighting`, `chiaroscuro`, `soft diffused light`, etc.
3. **Variants must differ** — each of the 3 variants must use a different style, medium, and mood. No overlapping aesthetic.
4. **Prompt length** — 2–4 sentences per variant. Long enough to be detailed, short enough for Gemini to parse cleanly.
5. **Subject grounded in idea** — the prompt must clearly derive from the idea's angle/hook, not be generic stock imagery.

---

## Plugin Metadata

### `skills/gemini-prompt-generator/.claude-plugin/plugin.json`
```json
{
  "name": "gemini-prompt-generator",
  "description": "Generate 3 Gemini-optimised image prompt variants per content idea. Reads ideas.md, writes prompts.md. No API key required.",
  "version": "1.0.0",
  "user-invocable": true
}
```

### Register in `skills/.claude-plugin/plugin.json`
Add `"./gemini-prompt-generator"` to the `skills` array in `skills/.claude-plugin/plugin.json`. This is required for the skill to be included in the published plugin bundle.

---

## Pipeline Integration

The skill inserts between `content-ideas` and `image-generator` in `youtube-pipeline`:

```
content-ideas → gemini-prompt-generator → prompts.md → [manual Gemini web] → images/
                                                      ↘ image-generator (API) → images/
```

### `youtube-pipeline` SKILL.md changes

**Step name:** `prompts` — add to the valid step names list alongside `transcript, summary, obsidian, ideas, images, social, tweets`.

**New Step 4b** (insert between ideas and images):

```
### Step 4b — Generate Gemini Prompts (optional, runs when GEMINI_API_KEY is not set)

Check for GEMINI_API_KEY:
- If set: proceed directly to Step 5 (image-generator handles this).
- If not set:
  1. Run: Skill("gemini-prompt-generator", "$OUTPUT_DIR/ideas.md")
  2. Confirmation gate (skip if --no-confirm):
     AskUserQuestion("Prompts saved to prompts.md. Generate images manually in Gemini,
     then place them in $OUTPUT_DIR/images/. Ready to continue? (y/n)")
  3. If user says yes: continue to Step 6 (social posts).
  4. If user says no: stop and print pipeline summary.
```

**Reconciling Step 4b with Step 5's existing no-key guard:**
Step 5 in the current `youtube-pipeline/SKILL.md` contains a guard: "if `GEMINI_API_KEY` is not set: warn and skip, continue." When Step 4b is added, that guard becomes unreachable (Step 4b already handles the no-key path and gates the user before Step 5 runs). The implementation must **remove** Step 5's existing no-key guard entirely. Step 5 should assume `GEMINI_API_KEY` is available when it runs (because Step 4b only reaches Step 5 when the key is set).

**`--skip-images` flag behaviour:** When `--skip-images` is passed, skip both Step 5 (image-generator) AND Step 4b (gemini-prompt-generator). The flag means "skip all image-related steps."

**Updated valid step names list** (add `prompts`):
```
Valid step names: transcript, summary, obsidian, ideas, prompts, images, social, tweets
```

**Pipeline Summary table update:**
Add a `prompts` row to the Pipeline Summary display in `youtube-pipeline/SKILL.md` between `ideas` and `images`:
```
[ ] prompts   → prompts.md
```
Status markers follow the same pattern as other steps: `[x]` completed, `[ ]` skipped, `[failed]` on error.

**`content-ideas` next steps update:**
Add `/gemini-prompt-generator` to the "Next steps" report in `content-ideas/SKILL.md` so users running the skill standalone are guided to the new skill:
```
Next steps:
- /gemini-prompt-generator path/to/ideas.md  — generate Gemini image prompts
- /image-generator path/to/ideas.md          — generate images via API
```

---

## File Structure

```
skills/
└── gemini-prompt-generator/
    ├── SKILL.md           ← execution instructions for Claude
    ├── README.md          ← human-readable docs
    └── .claude-plugin/
        └── plugin.json    ← skill metadata
```

No `scripts/` directory — this is a fully LLM-native skill.

---

## Companion Skill — Nano Banana Pro (optional install)

Alongside this skill, users can install the existing community skill for curated Gemini prompt discovery:
```bash
npx skills i YouMind-OpenLab/nano-banana-pro-prompts-recommend-skill
```

This provides a 10,000+ curated Gemini prompt library. The `gemini-prompt-generator` skill generates content-specific prompts from `ideas.md`; the Nano Banana skill provides curated prompt discovery from a library. They are complementary.

---

## Success Criteria

- Given a valid `ideas.md` with 5 ideas, produces a `prompts.md` with 15 prompt variants (5 × 3)
- Each variant is visually distinct from the other two for the same idea
- No banned terms (`beautiful`, `amazing`, `good lighting`) appear in any generated prompt
- Prompts are copy-pasteable into `gemini.google.com` without modification
- `youtube-pipeline` correctly routes to this skill when `GEMINI_API_KEY` is absent
- README clearly explains the manual workflow
- `skills/.claude-plugin/plugin.json` includes `"./gemini-prompt-generator"` in the skills array
