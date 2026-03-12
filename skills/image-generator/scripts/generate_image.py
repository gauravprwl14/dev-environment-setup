#!/usr/bin/env python3
"""Generate marketing-ready images using Google Gemini API."""

import argparse
import json
import os
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


def main():
    parser = argparse.ArgumentParser(description="Generate images via Gemini API")
    parser.add_argument("--prompt", required=True, help="Image generation prompt")
    parser.add_argument("--output-dir", required=True, help="Output directory for images")
    parser.add_argument("--sizes", default="1600x900,1200x627", help="Comma-separated WxH sizes")
    parser.add_argument("--name", default="image", help="Base name for output files")
    parser.add_argument("--manifest", default=None, help="Path to existing manifest to append to")
    args = parser.parse_args()

    # Load config: env var > ~/.config/content-pipeline/.env > ~/.config/image-generator/.env > defaults
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

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    sizes = []
    for s in args.sizes.split(","):
        w, h = s.strip().split("x")
        platform = "x" if (int(w), int(h)) == (1600, 900) else "linkedin" if (int(w), int(h)) == (1200, 627) else "custom"
        sizes.append({"width": int(w), "height": int(h), "platform": platform})

    try:
        from google import genai
        client = genai.Client(api_key=api_key)
    except ImportError:
        print("ERROR: google-genai package not installed. Run: pip3 install --user google-genai>=1.0.0", file=sys.stderr)
        sys.exit(1)

    # Primary: Gemini 3 Flash Image (best balance of speed/quality/cost)
    # Fallback chain: gemini-3.1-flash → gemini-2.5-flash → gemini-2.0-flash-exp
    GEMINI_IMAGE_MODELS = [
        "gemini-3-flash-image-preview",
        "gemini-3.1-flash-image-preview",
        "gemini-3-pro-image-preview",
        "gemini-2.5-flash-image",
        "gemini-2.0-flash-exp-image-generation",
    ]
    gemini_image_model = None
    available_models = {m.name.replace("models/", "") for m in client.models.list()}
    for m in GEMINI_IMAGE_MODELS:
        if m in available_models:
            gemini_image_model = m
            break

    if not gemini_image_model:
        print("ERROR: No Gemini image generation model available.", file=sys.stderr)
        print(f"Available models with 'image': {[m for m in available_models if 'image' in m.lower()]}", file=sys.stderr)
        sys.exit(1)

    print(f"Using model: {gemini_image_model}")

    generated_files = []

    for size in sizes:
        w, h = size["width"], size["height"]
        filename = f"{args.name}-{w}x{h}.png"
        filepath = output_dir / filename

        print(f"Generating {w}x{h} image: {filename}...")

        try:
            image_bytes = None

            response = client.models.generate_content(
                model=gemini_image_model,
                contents=f"Generate an image: {args.prompt}. Aspect ratio suitable for {w}x{h} pixels.",
                config=genai.types.GenerateContentConfig(
                    response_modalities=["IMAGE", "TEXT"],
                ),
            )
            if response.candidates:
                for part in response.candidates[0].content.parts:
                    if part.inline_data and part.inline_data.mime_type.startswith("image/"):
                        image_bytes = part.inline_data.data
                        break

            if image_bytes:
                with open(filepath, "wb") as f:
                    f.write(image_bytes)

                # Resize to exact dimensions
                try:
                    from PIL import Image
                    img = Image.open(filepath)
                    if img.size != (w, h):
                        img = img.resize((w, h), Image.LANCZOS)
                        img.save(filepath, "PNG")
                except ImportError:
                    print(f"  Warning: Pillow not installed, skipping resize to exact {w}x{h}", file=sys.stderr)

                generated_files.append({
                    "path": filename,
                    "width": w,
                    "height": h,
                    "platform": size["platform"]
                })
                print(f"  ✅ Saved: {filepath}")
            else:
                print(f"  ❌ No image generated for {w}x{h}", file=sys.stderr)

        except Exception as e:
            print(f"  ❌ Error generating {w}x{h}: {e}", file=sys.stderr)
            continue

    # Update or create manifest
    manifest_path = Path(args.manifest) if args.manifest else output_dir / "manifest.json"
    manifest = {"generated": datetime.now().isoformat(), "images": []}

    if manifest_path.exists():
        try:
            with open(manifest_path) as f:
                manifest = json.load(f)
        except (json.JSONDecodeError, OSError):
            pass

    manifest["images"].append({
        "name": args.name,
        "prompt": args.prompt,
        "files": generated_files
    })
    manifest["generated"] = datetime.now().isoformat()

    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)

    print(f"\nManifest updated: {manifest_path}")
    print(f"Generated {len(generated_files)} image(s)")


if __name__ == "__main__":
    main()
