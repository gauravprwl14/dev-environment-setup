# image-generator skill

Generate marketing-ready images using the Google Gemini image generation API.
Supports batch generation from a `content-ideas` pipeline output file or single
prompt generation for ad-hoc use.

---

## Prerequisites

### 1. Gemini API key

Get a free key at https://ai.dev (Google AI Studio).

```bash
export GEMINI_API_KEY=your-key-here
# or persist it:
echo 'GEMINI_API_KEY=your-key-here' >> ~/.config/content-pipeline/.env
```

### 2. Python dependencies

```bash
pip3 install --user google-genai>=1.0.0 Pillow>=10.0.0
```

---

## Usage

### Mode 1 — Batch from ideas.md

Pass a path to an `ideas.md` file produced by the `/content-ideas` skill.
The script parses every `## Idea N: <Title>` section, extracts the
`**Image prompt suggestion:**` field, and generates images for each idea.

```bash
# As a Claude Code skill
/image-generator path/to/ideas.md

# Direct script call
python3 scripts/generate_image.py path/to/ideas.md
```

Output is written to `<ideas.md-directory>/images/`:

```
images/
  idea-1-why-developers-burnout-1600x900.png
  idea-1-why-developers-burnout-1200x627.png
  idea-2-ai-is-not-replacing-devs-1600x900.png
  idea-2-ai-is-not-replacing-devs-1200x627.png
  manifest.json
```

### Mode 2 — Single prompt

```bash
# As a Claude Code skill
/image-generator --prompt "A developer staring at a glowing monitor at 3am, cinematic lighting"

# Direct script call with all options
python3 scripts/generate_image.py \
  --prompt "A developer staring at a glowing monitor at 3am, cinematic lighting" \
  --output-dir ./images \
  --name "burnout-hero" \
  --sizes "1600x900,1200x627" \
  --manifest ./images/manifest.json
```

#### Mode 2 options

| Flag | Default | Description |
|------|---------|-------------|
| `--prompt` | (required) | Image generation prompt |
| `--output-dir` | `./images` | Directory to save images |
| `--name` | `image` | Base filename (size suffix appended automatically) |
| `--sizes` | `1600x900,1200x627` | Comma-separated `WxH` list |
| `--manifest` | `<output-dir>/manifest.json` | Path to manifest file (appended if exists) |

---

## Output format

### Image files

Generated as PNG. File names follow the pattern `<name>-<W>x<H>.png`.

Default sizes and their target platforms:
- `1600x900` → X (Twitter)
- `1200x627` → LinkedIn
- Any other size → labelled `custom`

### manifest.json

Created (or updated) in the output directory after each run.

```json
{
  "generated": "2026-03-20T14:22:00.000000",
  "images": [
    {
      "idea_number": 1,
      "title": "Why Developers Burnout",
      "name": "idea-1-why-developers-burnout",
      "prompt": "Create a cinematic image showing a developer at 3am...",
      "files": [
        { "path": "idea-1-why-developers-burnout-1600x900.png", "width": 1600, "height": 900, "platform": "x" },
        { "path": "idea-1-why-developers-burnout-1200x627.png", "width": 1200, "height": 627, "platform": "linkedin" }
      ]
    }
  ]
}
```

In Mode 1, the manifest is written after each idea so partial progress is
preserved if generation is interrupted.

---

## Gemini models used

The script tries models in this order (first available wins):

1. `gemini-2.0-flash-exp-image-generation`
2. `gemini-2.0-flash-exp`
3. `imagen-3.0-generate-002`
4. `imagen-3.0-generate-001`
5. `imagegeneration@006`

Model availability depends on your API key tier and Google's rollout schedule.
To list image-capable models available to your key:

```bash
python3 - <<'EOF'
import os
from google import genai
c = genai.Client(api_key=os.environ["GEMINI_API_KEY"])
for m in c.models.list():
    if "image" in m.name.lower() or "imagen" in m.name.lower():
        print(m.name)
EOF
```

---

## Troubleshooting

### GEMINI_API_KEY not set

```
ERROR: GEMINI_API_KEY not found.
Set it via:
  export GEMINI_API_KEY=your-key
  # or add to ~/.config/content-pipeline/.env
```

Fix: export the variable or add it to `~/.config/content-pipeline/.env`.

### No image generation models available

```
ERROR: No Gemini image generation model available.
Models containing 'image'/'imagen': []
```

Causes:
- Your API key is on a free tier that does not yet have access to image models.
- Google has renamed or removed models — update `GEMINI_IMAGE_MODELS` at the
  top of `scripts/generate_image.py` with current model names.
- Run the model-listing snippet above to see what is actually available.

### No image prompts found in ideas.md

```
ERROR: No ideas with image prompts found in the file.
Make sure your ideas.md contains '**Image prompt suggestion:**' fields.
```

The script expects ideas in the format produced by `/content-ideas`:
```markdown
## Idea 1: Your Title
- **Image prompt suggestion:** [Create a ...]
```

If your ideas.md uses a different label, check `_extract_image_prompt()` in
`scripts/generate_image.py` and add a matching regex pattern.

### Pillow not installed (resize skipped)

```
Warning: Pillow not installed, skipping resize to 1600x900.
```

Images are saved at the resolution returned by the API (may differ from
requested size). Install Pillow to enable automatic resizing:

```bash
pip3 install --user Pillow>=10.0.0
```

---

## Pipeline integration

This skill is part of the content pipeline:

```
/content-summarizer <url>     →  summary.md
/content-ideas summary.md     →  ideas.md
/image-generator ideas.md     →  images/ + manifest.json   ← you are here
/social-posts ideas.md        →  posts ready for publishing
```
