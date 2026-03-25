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
