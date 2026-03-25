#!/usr/bin/env python3
"""Extract transcript from a YouTube video URL.

Outputs markdown with YAML frontmatter containing video metadata and full transcript.
"""

import re
import sys
import os
import tempfile
import subprocess
import json
from datetime import date
from pathlib import Path

# Add shared config to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "lib"))
try:
    from config import get_config
except ImportError:
    # Fallback: standalone mode without shared config
    get_config = None


def extract_video_id(url: str) -> str | None:
    """Extract YouTube video ID from various URL formats."""
    patterns = [
        r'(?:youtube\.com/watch\?.*v=|youtube\.com/embed/|youtube\.com/v/|youtu\.be/|youtube\.com/shorts/)([a-zA-Z0-9_-]{11})',
        r'^([a-zA-Z0-9_-]{11})$',
    ]
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None


def format_duration(seconds: float | int) -> str:
    """Format seconds into HH:MM:SS or MM:SS."""
    seconds = int(seconds)
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60
    if hours > 0:
        return f"{hours}:{minutes:02d}:{secs:02d}"
    return f"{minutes}:{secs:02d}"


def _clean_vtt(vtt_text: str) -> str:
    """Convert VTT subtitle format to clean plaintext."""
    text = re.sub(r'^WEBVTT.*?\n\n', '', vtt_text, flags=re.DOTALL)
    text = re.sub(r'\d{2}:\d{2}:\d{2}\.\d{3}\s*-->\s*\d{2}:\d{2}:\d{2}\.\d{3}.*\n', '', text)
    text = re.sub(r'<[^>]+>', '', text)
    text = re.sub(r'^\d+\s*$', '', text, flags=re.MULTILINE)
    lines = text.strip().split('\n')
    seen = set()
    unique = []
    for line in lines:
        stripped = line.strip()
        if stripped and stripped not in seen:
            seen.add(stripped)
            unique.append(stripped)
    return re.sub(r'\s+', ' ', ' '.join(unique)).strip()


def fetch_metadata(video_id: str) -> dict:
    """Fetch video metadata using yt-dlp."""
    url = f"https://www.youtube.com/watch?v={video_id}"
    try:
        result = subprocess.run(
            [
                "yt-dlp",
                "--skip-download",
                "--print-json",
                "--no-warnings",
                url,
            ],
            capture_output=True,
            text=True,
            timeout=60,
        )
        if result.returncode == 0 and result.stdout.strip():
            data = json.loads(result.stdout.strip())
            return {
                "title": data.get("title", "Unknown Title"),
                "channel": data.get("channel", data.get("uploader", "Unknown Channel")),
                "duration": format_duration(data.get("duration", 0)),
                "description": data.get("description", ""),
            }
    except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
        pass
    return {
        "title": "Unknown Title",
        "channel": "Unknown Channel",
        "duration": "0:00",
        "description": "",
    }


def fetch_transcript_api(video_id: str) -> str | None:
    """Fetch transcript using youtube_transcript_api."""
    try:
        from youtube_transcript_api import YouTubeTranscriptApi

        ytt_api = YouTubeTranscriptApi()
        transcript = ytt_api.fetch(video_id)
        lines = [entry.text for entry in transcript]
        return " ".join(lines)
    except Exception:
        return None


def fetch_transcript_ytdlp(video_id: str) -> str | None:
    """Fetch transcript using yt-dlp auto-subs as fallback."""
    url = f"https://www.youtube.com/watch?v={video_id}"
    with tempfile.TemporaryDirectory() as tmpdir:
        output_template = os.path.join(tmpdir, "subs")
        try:
            subprocess.run(
                [
                    "yt-dlp",
                    "--skip-download",
                    "--write-auto-sub",
                    "--sub-lang", "en",
                    "--sub-format", "vtt",
                    "--output", output_template,
                    "--no-warnings",
                    url,
                ],
                capture_output=True,
                text=True,
                timeout=60,
            )
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return None

        # Find the generated subtitle file
        for fname in os.listdir(tmpdir):
            if fname.endswith(".vtt"):
                vtt_path = os.path.join(tmpdir, fname)
                with open(vtt_path, "r", encoding="utf-8") as f:
                    vtt_text = f.read()
                return _clean_vtt(vtt_text)
    return None


def main():
    if len(sys.argv) < 2:
        print("Error: No YouTube URL provided.", file=sys.stderr)
        print(f"Usage: {sys.argv[0]} <youtube-url>", file=sys.stderr)
        sys.exit(1)

    url = sys.argv[1]
    video_id = extract_video_id(url)

    if not video_id:
        print("Error: Invalid YouTube URL. Please provide a valid youtube.com or youtu.be link.", file=sys.stderr)
        sys.exit(1)

    canonical_url = f"https://www.youtube.com/watch?v={video_id}"

    # Load config (env var > .env file > defaults)
    if get_config:
        cfg = get_config("yt-transcript")
    else:
        cfg = {}

    # Fetch metadata
    metadata = fetch_metadata(video_id)

    # Try youtube-transcript-api first
    transcript = fetch_transcript_api(video_id)
    source = "youtube-transcript-api"

    # Fall back to yt-dlp
    if not transcript:
        transcript = fetch_transcript_ytdlp(video_id)
        source = "yt-dlp"

    if not transcript:
        print(
            "Error: This video has no captions/subtitles available "
            "(neither manual nor auto-generated).",
            file=sys.stderr,
        )
        sys.exit(1)

    # Escape any quotes in title for YAML frontmatter
    safe_title = metadata["title"].replace('"', '\\"')
    safe_channel = metadata["channel"].replace('"', '\\"')

    # Output markdown with YAML frontmatter
    output = f"""---
title: "{safe_title}"
channel: "{safe_channel}"
url: "{canonical_url}"
duration: "{metadata['duration']}"
date_extracted: "{date.today().isoformat()}"
source: "{source}"
---

# {metadata['title']}

{transcript}
"""
    print(output)


if __name__ == "__main__":
    main()
