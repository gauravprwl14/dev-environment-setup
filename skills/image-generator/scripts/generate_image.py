#!/usr/bin/env python3
"""Generate marketing-ready images using Google Gemini API.

Modes:
  Mode 1: python3 generate_image.py <path/to/ideas.md>
          Parses all ideas from an ideas.md file, extracts each idea's
          "Image prompt suggestion" and generates one image per idea.

  Mode 2: python3 generate_image.py --prompt "..." [--output-dir DIR]
                                     [--name NAME] [--sizes WxH,WxH]
                                     [--manifest PATH]
          Generates images for a single prompt.
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

# Add shared config to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "lib"))
try:
    from config import get_config, diagnose
except ImportError:
    get_config = None
    diagnose = None

# ---------------------------------------------------------------------------
# Gemini image model fallback chain (as of early 2026).
#
# Model availability changes over time. To check which models are currently
# available on your API key, run:
#   python3 -c "
#   import os; from google import genai
#   c = genai.Client(api_key=os.environ['GEMINI_API_KEY'])
#   [print(m.name) for m in c.models.list() if 'image' in m.name.lower()]
#   "
# ---------------------------------------------------------------------------
GEMINI_IMAGE_MODELS = [
    # Gemini multimodal models (work on free tier — tried first)
    "gemini-2.5-flash-image",                 # Gemini 2.5 Flash with image output
    "gemini-3.1-flash-image-preview",         # Gemini 3.1 Flash image preview
    "gemini-3-pro-image-preview",             # Gemini 3 Pro image preview
    # Imagen 4 models (higher quality, require paid Google AI plan)
    "imagen-4.0-fast-generate-001",           # Imagen 4 Fast (lowest latency)
    "imagen-4.0-generate-001",                # Imagen 4 (high quality)
    "imagen-4.0-ultra-generate-001",          # Imagen 4 Ultra (highest quality)
]


# ---------------------------------------------------------------------------
# ideas.md parsing
# ---------------------------------------------------------------------------

def parse_ideas(ideas_path: Path) -> list[dict]:
    """Parse ideas.md and return a list of dicts with keys: title, number, prompt.

    The ideas.md format produced by the content-ideas skill uses this pattern:

        ## Idea 1: <Title>
        ...
        - **Image prompt suggestion:** [prompt text here]
        ...
        ## Idea 2: <Title>
        ...

    Returns list of:
        {
            "number": 1,
            "title": "Title Here",
            "slug": "title-here",
            "prompt": "Create a ...",
        }
    """
    text = ideas_path.read_text(encoding="utf-8")

    # Split on idea headings: "## Idea N: Title" (case-insensitive)
    idea_block_pattern = re.compile(
        r"^##\s+Idea\s+(\d+)\s*:\s*(.+)$",
        re.MULTILINE | re.IGNORECASE,
    )

    matches = list(idea_block_pattern.finditer(text))
    ideas = []

    for i, match in enumerate(matches):
        number = int(match.group(1))
        title = match.group(2).strip()
        slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")[:40]

        # Extract the block for this idea (up to the next idea heading or end)
        block_start = match.end()
        block_end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        block = text[block_start:block_end]

        # Look for "Image prompt suggestion:" — handles bold markers, brackets,
        # inline backtick wrapping, and multi-line values.
        prompt = _extract_image_prompt(block)

        if prompt:
            ideas.append({
                "number": number,
                "title": title,
                "slug": slug,
                "prompt": prompt,
            })
        else:
            print(
                f"  Warning: No image prompt found for Idea {number} ({title!r}), skipping.",
                file=sys.stderr,
            )

    return ideas


def _extract_image_prompt(block: str) -> str | None:
    """Extract the image prompt from a single idea block.

    Tries multiple patterns to accommodate minor formatting differences:
      1. "**Image prompt suggestion:**"  (bold label)
      2. "**Image Prompt:**"             (alternate bold label)
      3. "Image prompt suggestion:"      (plain label)
    The value may be:
      - Inline on the same line (optionally wrapped in brackets or backticks)
      - On the next line as a blockquote or plain paragraph
    """
    patterns = [
        # Colon INSIDE bold markers: **Image prompt suggestion:** [text]  (standard content-ideas format)
        r"\*\*Image prompt suggestion[s]?:\*\*\s*\[?([^\]\n]+)\]?",
        r"\*\*Image Prompt suggestion[s]?:\*\*\s*\[?([^\]\n]+)\]?",
        r"\*\*Image Prompt:\*\*\s*\[?([^\]\n]+)\]?",
        r"\*\*Image prompt:\*\*\s*\[?([^\]\n]+)\]?",
        # Colon OUTSIDE bold markers: **Image prompt suggestion** : [text]
        r"\*\*Image prompt suggestion[s]?\*\*\s*[:\-]\s*\[?([^\]\n]+)\]?",
        r"\*\*Image Prompt suggestion[s]?\*\*\s*[:\-]\s*\[?([^\]\n]+)\]?",
        r"\*\*Image Prompt\*\*\s*[:\-]\s*\[?([^\]\n]+)\]?",
        r"\*\*Image prompt\*\*\s*[:\-]\s*\[?([^\]\n]+)\]?",
        # Plain label variants (no bold)
        r"Image prompt suggestion[s]?\s*[:\-]\s*\[?([^\]\n]+)\]?",
        r"Image Prompt\s*[:\-]\s*\[?([^\]\n]+)\]?",
    ]

    for pattern in patterns:
        m = re.search(pattern, block, re.IGNORECASE)
        if m:
            raw = m.group(1).strip()
            # Strip surrounding quotes or backticks
            raw = raw.strip('"\'`')
            if raw:
                return raw

    return None


# ---------------------------------------------------------------------------
# Gemini client helpers
# ---------------------------------------------------------------------------

def build_client(api_key: str):
    try:
        from google import genai
        return genai.Client(api_key=api_key), genai
    except ImportError:
        print(
            "ERROR: google-genai package not installed. Run: pip3 install --user google-genai>=1.0.0",
            file=sys.stderr,
        )
        sys.exit(1)


def pick_model(client) -> str | None:
    """Return the first available model from GEMINI_IMAGE_MODELS, or None."""
    available = {m.name.replace("models/", "") for m in client.models.list()}
    for model in GEMINI_IMAGE_MODELS:
        if model in available:
            return model
    # Also check with "models/" prefix stripped variants
    available_bare = {m.replace("models/", "") for m in available}
    for model in GEMINI_IMAGE_MODELS:
        bare = model.replace("models/", "")
        if bare in available_bare:
            return model
    return None


# ---------------------------------------------------------------------------
# Image generation
# ---------------------------------------------------------------------------

def _aspect_ratio_str(w: int, h: int) -> str:
    """Return the closest Imagen-supported aspect ratio string for w x h."""
    ratio = w / h
    # Imagen 4 supported aspect ratios: 1:1, 3:4, 4:3, 9:16, 16:9
    candidates = {
        "1:1": 1.0,
        "4:3": 4 / 3,
        "3:4": 3 / 4,
        "16:9": 16 / 9,
        "9:16": 9 / 16,
    }
    return min(candidates, key=lambda k: abs(candidates[k] - ratio))


def _call_api(client, genai, model: str, prompt: str, w: int, h: int) -> bytes | None:
    """Call the appropriate API based on model type. Returns raw image bytes or None."""
    if model.startswith("imagen"):
        # Imagen models use generate_images(), not generate_content()
        aspect = _aspect_ratio_str(w, h)
        response = client.models.generate_images(
            model=model,
            prompt=prompt,
            config=genai.types.GenerateImagesConfig(
                number_of_images=1,
                aspect_ratio=aspect,
            ),
        )
        if response.generated_images:
            return response.generated_images[0].image.image_bytes
        return None
    else:
        # Gemini multimodal models use generate_content() with IMAGE modality
        response = client.models.generate_content(
            model=model,
            contents=(
                f"Generate an image: {prompt}. "
                f"Aspect ratio suitable for {w}x{h} pixels."
            ),
            config=genai.types.GenerateContentConfig(
                response_modalities=["IMAGE", "TEXT"],
            ),
        )
        if response.candidates:
            for part in response.candidates[0].content.parts:
                if part.inline_data and part.inline_data.mime_type.startswith("image/"):
                    return part.inline_data.data
        return None


def generate_images_for_prompt(
    client,
    genai,
    model: str,
    prompt: str,
    output_dir: Path,
    base_name: str,
    sizes: list[dict],
) -> list[dict]:
    """Generate one image per size for `prompt`. Returns list of file records."""
    generated_files = []

    for size in sizes:
        w, h = size["width"], size["height"]
        filename = f"{base_name}-{w}x{h}.png"
        filepath = output_dir / filename

        print(f"  Generating {w}x{h}: {filename}...")

        try:
            image_bytes = _call_api(client, genai, model, prompt, w, h)

            if not image_bytes:
                # Retry once
                print(f"    No image returned, retrying {w}x{h}...")
                image_bytes = _call_api(client, genai, model, prompt, w, h)

            if image_bytes:
                with open(filepath, "wb") as f:
                    f.write(image_bytes)

                # Resize to exact dimensions if needed
                try:
                    from PIL import Image
                    img = Image.open(filepath)
                    if img.size != (w, h):
                        img = img.resize((w, h), Image.LANCZOS)
                        img.save(filepath, "PNG")
                except ImportError:
                    pass  # Pillow optional — image saved at native resolution

                generated_files.append({
                    "path": filename,
                    "width": w,
                    "height": h,
                    "platform": size["platform"],
                })
                print(f"    Saved: {filepath}")
            else:
                print(f"    No image data returned for {w}x{h}.", file=sys.stderr)

        except Exception as e:
            print(f"    Error generating {w}x{h}: {e}", file=sys.stderr)
            try:
                print(f"    Retrying {w}x{h}...")
                image_bytes = _call_api(client, genai, model, prompt, w, h)
                if image_bytes:
                    with open(filepath, "wb") as f:
                        f.write(image_bytes)
                    generated_files.append({
                        "path": filename,
                        "width": w,
                        "height": h,
                        "platform": size["platform"],
                    })
                    print(f"    Saved (retry): {filepath}")
                else:
                    print(f"    Retry returned no image for {w}x{h}.", file=sys.stderr)
            except Exception as e2:
                print(f"    Retry failed for {w}x{h}: {e2}", file=sys.stderr)

    return generated_files


def load_or_create_manifest(manifest_path: Path) -> dict:
    manifest = {"generated": datetime.now().isoformat(), "images": []}
    if manifest_path.exists():
        try:
            with open(manifest_path) as f:
                manifest = json.load(f)
        except (json.JSONDecodeError, OSError):
            pass
    return manifest


def save_manifest(manifest_path: Path, manifest: dict) -> None:
    manifest["generated"] = datetime.now().isoformat()
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)


def parse_sizes(sizes_str: str) -> list[dict]:
    sizes = []
    for s in sizes_str.split(","):
        w, h = s.strip().split("x")
        w, h = int(w), int(h)
        if (w, h) == (1600, 900):
            platform = "x"
        elif (w, h) == (1200, 627):
            platform = "linkedin"
        else:
            platform = "custom"
        sizes.append({"width": w, "height": h, "platform": platform})
    return sizes


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    # Detect mode before full argparse so we can support positional ideas.md path
    if len(sys.argv) == 2 and not sys.argv[1].startswith("--"):
        # Mode 1: positional argument is a path (not a flag)
        run_mode1(sys.argv[1])
        return

    parser = argparse.ArgumentParser(description="Generate images via Gemini API")
    parser.add_argument("--prompt", required=True, help="Image generation prompt")
    parser.add_argument("--output-dir", required=True, help="Output directory for images")
    parser.add_argument("--sizes", default="1600x900,1200x627", help="Comma-separated WxH sizes")
    parser.add_argument("--name", default="image", help="Base name for output files")
    parser.add_argument("--manifest", default=None, help="Path to existing manifest to append to")
    args = parser.parse_args()

    run_mode2(
        prompt=args.prompt,
        output_dir=Path(args.output_dir),
        sizes_str=args.sizes,
        base_name=args.name,
        manifest_path=Path(args.manifest) if args.manifest else None,
    )


def _load_api_key() -> str:
    if get_config:
        cfg = get_config("image-generator")
    else:
        cfg = {}

    api_key = cfg.get("GEMINI_API_KEY") or os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("ERROR: GEMINI_API_KEY not found.", file=sys.stderr)
        print("", file=sys.stderr)
        if diagnose:
            print(diagnose("image-generator", [
                ("GEMINI_API_KEY", "Required — get one at https://ai.dev"),
            ]), file=sys.stderr)
        else:
            print("Set it via:", file=sys.stderr)
            print("  export GEMINI_API_KEY=your-key", file=sys.stderr)
            print("  # or add to ~/.config/content-pipeline/.env", file=sys.stderr)
        sys.exit(1)
    return api_key


def run_mode1(ideas_file: str) -> None:
    """Mode 1: Parse ideas.md and generate one image per idea."""
    ideas_path = Path(ideas_file).expanduser().resolve()

    if not ideas_path.exists():
        print(f"ERROR: File not found: {ideas_path}", file=sys.stderr)
        sys.exit(1)

    if not ideas_path.is_file():
        print(f"ERROR: Not a file: {ideas_path}", file=sys.stderr)
        sys.exit(1)

    print(f"Mode 1: Reading ideas from {ideas_path}")

    ideas = parse_ideas(ideas_path)
    if not ideas:
        print("ERROR: No ideas with image prompts found in the file.", file=sys.stderr)
        print("Make sure your ideas.md contains '**Image prompt suggestion:**' fields.", file=sys.stderr)
        sys.exit(1)

    print(f"Found {len(ideas)} idea(s) with image prompts.")

    api_key = _load_api_key()
    client, genai = build_client(api_key)

    model = pick_model(client)
    if not model:
        available = {m.name.replace("models/", "") for m in client.models.list()}
        image_models = [m for m in available if "image" in m.lower() or "imagen" in m.lower()]
        print("ERROR: No Gemini image generation model available.", file=sys.stderr)
        print(f"Models containing 'image'/'imagen': {image_models}", file=sys.stderr)
        print("Update GEMINI_IMAGE_MODELS in this script or check your API key permissions.", file=sys.stderr)
        sys.exit(1)

    print(f"Using model: {model}")

    output_dir = ideas_path.parent / "images"
    output_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = output_dir / "manifest.json"

    sizes = parse_sizes("1600x900,1200x627")
    manifest = load_or_create_manifest(manifest_path)

    total_generated = 0

    for idea in ideas:
        n = idea["number"]
        print(f"\n[Idea {n}/{len(ideas)}] {idea['title']}")
        print(f"  Prompt: {idea['prompt'][:80]}{'...' if len(idea['prompt']) > 80 else ''}")

        base_name = f"idea-{n}-{idea['slug']}"
        files = generate_images_for_prompt(
            client, genai, model,
            prompt=idea["prompt"],
            output_dir=output_dir,
            base_name=base_name,
            sizes=sizes,
        )

        if files:
            total_generated += len(files)
            # Update or replace entry for this idea in manifest
            existing = next(
                (e for e in manifest["images"] if e.get("idea_number") == n), None
            )
            entry = {
                "idea_number": n,
                "title": idea["title"],
                "name": base_name,
                "prompt": idea["prompt"],
                "files": files,
            }
            if existing:
                manifest["images"][manifest["images"].index(existing)] = entry
            else:
                manifest["images"].append(entry)

            save_manifest(manifest_path, manifest)
        else:
            print(f"  No images generated for Idea {n}.", file=sys.stderr)

    print(f"\n--- Mode 1 Complete ---")
    print(f"Ideas processed : {len(ideas)}")
    print(f"Images generated: {total_generated}")
    print(f"Output directory: {output_dir}")
    print(f"Manifest        : {manifest_path}")


def run_mode2(
    prompt: str,
    output_dir: Path,
    sizes_str: str,
    base_name: str,
    manifest_path: Path | None,
) -> None:
    """Mode 2: Generate images for a single prompt."""
    api_key = _load_api_key()
    client, genai = build_client(api_key)

    model = pick_model(client)
    if not model:
        available = {m.name.replace("models/", "") for m in client.models.list()}
        image_models = [m for m in available if "image" in m.lower() or "imagen" in m.lower()]
        print("ERROR: No Gemini image generation model available.", file=sys.stderr)
        print(f"Models containing 'image'/'imagen': {image_models}", file=sys.stderr)
        print("Update GEMINI_IMAGE_MODELS in this script or check your API key permissions.", file=sys.stderr)
        sys.exit(1)

    print(f"Using model: {model}")

    output_dir.mkdir(parents=True, exist_ok=True)
    sizes = parse_sizes(sizes_str)

    files = generate_images_for_prompt(
        client, genai, model,
        prompt=prompt,
        output_dir=output_dir,
        base_name=base_name,
        sizes=sizes,
    )

    resolved_manifest = manifest_path if manifest_path else output_dir / "manifest.json"
    manifest = load_or_create_manifest(resolved_manifest)

    manifest["images"].append({
        "name": base_name,
        "prompt": prompt,
        "files": files,
    })
    save_manifest(resolved_manifest, manifest)

    print(f"\nManifest updated: {resolved_manifest}")
    print(f"Generated {len(files)} image(s)")


if __name__ == "__main__":
    main()
