---
name: image-generator
description: "Generate marketing-ready images using Google Gemini API. Reads image prompts from ideas.md and generates platform-sized images."
argument-hint: 'image-generator path/to/ideas.md, image-generator --prompt "a futuristic city"'
allowed-tools: Bash, Read, Write
---

# Image Generator

Generate marketing-ready images from content ideas using Google Gemini image generation API.

## Execution Logic

Check `$ARGUMENTS`:
- If **empty** → respond: "Image Generator loaded. Usage: `/image-generator <path-to-ideas.md>` or `/image-generator --prompt \"description\"`" and STOP.
- If **value does NOT start with `--`** → treat as a path to an `ideas.md` file → **Mode 1**.
- If **value starts with `--prompt`** → **Mode 2**.

## Configuration

```bash
# Load config (env var > shared .env > per-skill .env > defaults)
for dir in \
  "$(dirname "${SKILL_ROOT:-.}")" \
  "${CLAUDE_PLUGIN_ROOT:+${CLAUDE_PLUGIN_ROOT}/..}" \
  "$HOME/.claude/skills" \
  "$HOME/.openclaw/workspace/skills"; do
  [ -n "$dir" ] && [ -f "$dir/lib/config.sh" ] && source "$dir/lib/config.sh" && break
done 2>/dev/null
load_pipeline_config "image-generator" 2>/dev/null || source ~/.config/content-pipeline/.env 2>/dev/null
```

If `GEMINI_API_KEY` is not set:
- Show diagnostic: which config files were checked, what's missing
- Suggest: `export GEMINI_API_KEY=your-key` or add to `~/.config/content-pipeline/.env`
- Do NOT hard-fail — skip image generation and continue the pipeline

## Dependencies Check

```bash
pip3 list 2>/dev/null | grep -qi "google-genai" || pip3 install --user google-genai>=1.0.0
pip3 list 2>/dev/null | grep -qi "Pillow" || pip3 install --user Pillow>=10.0.0
```

## Task Execution

### Mode 1: From ideas.md file

Triggered when `$ARGUMENTS` is a file path (does not start with `--`).

**How the script detects an ideas.md file vs a --prompt flag:**
The script checks `sys.argv[1]`: if it exists, is a single argument, and does not start with `--`, it runs in Mode 1 treating the argument as a file path.

**Parsing logic:**
1. The script reads the ideas.md file produced by the `content-ideas` skill.
2. It splits the file on headings matching `## Idea N: <Title>` (case-insensitive).
3. For each idea block, it searches for the line matching `**Image prompt suggestion:**` (or close variants like `**Image Prompt:**`).
4. The prompt text after the label is extracted — surrounding brackets, quotes, and backticks are stripped.
5. Ideas without an image prompt field are skipped with a warning.

**Output file naming convention:**
Each idea produces files named: `idea-<N>-<slug>-<WxH>.png`

- `N` is the idea number from the heading (e.g. `1`, `2`)
- `slug` is the idea title lowercased, non-alphanumeric runs replaced with `-`, truncated to 40 chars
- Default sizes: `1600x900` (X / Twitter) and `1200x627` (LinkedIn)

Examples:
```
idea-1-why-developers-burnout-1600x900.png
idea-1-why-developers-burnout-1200x627.png
idea-2-ai-is-not-replacing-devs-1600x900.png
```

**Invocation:**

```bash
for dir in \
  "." \
  "${CLAUDE_PLUGIN_ROOT:-}" \
  "$HOME/.claude/skills/image-generator" \
  "$HOME/.agents/skills/image-generator" \
  "$HOME/.codex/skills/image-generator"; do
  [ -n "$dir" ] && [ -f "$dir/scripts/generate_image.py" ] && SKILL_ROOT="$dir" && break
done

python3 "${SKILL_ROOT}/scripts/generate_image.py" "<path-to-ideas.md>"
```

Images are saved to `<ideas.md-directory>/images/`.

**manifest.json format (Mode 1):**
```json
{
  "generated": "2026-03-20T14:22:00.000000",
  "images": [
    {
      "idea_number": 1,
      "title": "Why Developers Burnout",
      "name": "idea-1-why-developers-burnout",
      "prompt": "Create a cinematic image showing...",
      "files": [
        { "path": "idea-1-why-developers-burnout-1600x900.png", "width": 1600, "height": 900, "platform": "x" },
        { "path": "idea-1-why-developers-burnout-1200x627.png", "width": 1200, "height": 627, "platform": "linkedin" }
      ]
    }
  ]
}
```

The manifest is updated incrementally after each idea — if generation is interrupted, progress is preserved.

### Mode 2: Direct prompt

If `$ARGUMENTS` contains `--prompt`:

1. Parse `--prompt "..."` and optional `--output-dir`, `--name`, `--sizes`, `--manifest`
2. Default output dir: current directory's `images/`
3. Default sizes: `1600x900,1200x627`
4. Default base name: `image`

```bash
python3 "${SKILL_ROOT}/scripts/generate_image.py" \
  --prompt "<image prompt>" \
  --output-dir "<output-dir>" \
  --name "idea-<N>-<slug>" \
  --sizes "1600x900,1200x627"
```

**manifest.json format (Mode 2):**
```json
{
  "generated": "2026-03-20T14:22:00.000000",
  "images": [
    {
      "name": "my-image",
      "prompt": "Create a...",
      "files": [
        { "path": "my-image-1600x900.png", "width": 1600, "height": 900, "platform": "x" },
        { "path": "my-image-1200x627.png", "width": 1200, "height": 627, "platform": "linkedin" }
      ]
    }
  ]
}
```

## Report Results

```
Images generated: <N> ideas x <M> sizes = <total> images
Saved to: <path>/images/
Manifest: <path>/images/manifest.json

Generated images:
- idea-1-slug-1600x900.png (X)
- idea-1-slug-1200x627.png (LinkedIn)
- idea-2-slug-1600x900.png (X)
[...]

Next: Run `/social-posts <path>/ideas.md` to pair posts with images.
```

## Error Handling
- **Missing GEMINI_API_KEY** → Clear setup instructions printed to stderr, script exits with code 1
- **ideas.md not found** → Error message + exit 1
- **No image prompts in file** → Error message listing what fields are expected + exit 1
- **No available model** → Lists all models containing "image"/"imagen" in name for diagnosis; exit 1
- **API error per image** → Retried once automatically; if retry fails, logged and skipped — other ideas continue
- **API quota exceeded** → Partial manifest is saved with whatever succeeded before the error
- **Invalid prompt** → Logged as error, skipped, next idea continues
- **Pillow not installed** → Images are saved at generated resolution without resizing; warning printed
