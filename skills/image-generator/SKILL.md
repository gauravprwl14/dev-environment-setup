---
name: image-generator
description: "Generate marketing-ready images using Google Gemini API. Reads image prompts from ideas.md and generates platform-sized images."
argument-hint: 'image-generator path/to/ideas.md, image-generator --prompt "a futuristic city"'
allowed-tools: Bash, Read, Write
---

# Image Generator

Generate marketing-ready images from content ideas using Google Gemini 3 Flash Image API.

## Execution Logic

Check `$ARGUMENTS`:
- If **empty** → respond: "Image Generator loaded. Usage: `/image-generator <path-to-ideas.md>` or `/image-generator --prompt \"description\"`" and STOP.
- If **has arguments** → parse and execute below.

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

If `$ARGUMENTS` is a path to an ideas.md file:

1. **Read ideas.md** and extract all image prompt suggestions.
2. **For each idea with an image prompt**, run the generation script:

```bash
for dir in \
  "." \
  "${CLAUDE_PLUGIN_ROOT:-}" \
  "$HOME/.claude/skills/image-generator" \
  "$HOME/.agents/skills/image-generator" \
  "$HOME/.codex/skills/image-generator"; do
  [ -n "$dir" ] && [ -f "$dir/scripts/generate_image.py" ] && SKILL_ROOT="$dir" && break
done

python3 "${SKILL_ROOT}/scripts/generate_image.py" \
  --prompt "<image prompt from idea>" \
  --output-dir "<same-dir-as-ideas>/images/" \
  --name "idea-<N>-<slug>" \
  --sizes "1600x900,1200x627"
```

3. After all images are generated, report results.

### Mode 2: Direct prompt

If `$ARGUMENTS` contains `--prompt`:

1. Parse `--prompt "..."` and optional `--output-dir`, `--name`, `--sizes`
2. Default output dir: current directory's `images/`
3. Run the script with provided arguments.

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
- **Missing GEMINI_API_KEY** → Clear setup instructions, continue pipeline without images
- **API quota exceeded** → Report which images succeeded, save partial manifest
- **Network error** → Retry once, then report failure for that image
- **Invalid prompt** → Log error, skip to next idea
