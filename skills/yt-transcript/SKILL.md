---
name: yt-transcript
description: "Extract transcript from any YouTube video URL. Returns full transcript as markdown with video metadata."
argument-hint: 'yt-transcript https://www.youtube.com/watch?v=VIDEO_ID'
allowed-tools: Bash, Read, Write
---

# YouTube Transcript Extractor

Extract the full transcript from any YouTube video URL.

## Execution Logic

Check `$ARGUMENTS`:

- If **empty** → respond: "YouTube Transcript loaded. Usage: `/yt-transcript <youtube-url>`" and STOP.
- If **has arguments** → treat as YouTube URL and execute below.

## Dependencies Check

Before running the extraction script, verify dependencies are installed:

```bash
pip3 list 2>/dev/null | grep -qi "youtube-transcript-api" || pip3 install --user youtube-transcript-api>=1.2.4
which yt-dlp >/dev/null 2>&1 || pip3 install --user yt-dlp
```

## Task Execution

1. **Parse the URL** from `$ARGUMENTS` — extract the YouTube URL (first argument that looks like a URL)

2. **Determine output directory**:
   - Use env var `CONTENT_PIPELINE_OUTPUT` if set, else `~/content-pipeline/output/`
   - Create subdirectory: `<YYYY-MM-DD-HH-MM-slug>/` where slug is derived from video title (lowercase, hyphens, max 50 chars)
   - Load env:
     ```bash
     # Load config (env var > shared .env > per-skill .env > defaults)
     for dir in \
       "$(dirname "${SKILL_ROOT:-.}")" \
       "${CLAUDE_PLUGIN_ROOT:+${CLAUDE_PLUGIN_ROOT}/..}" \
       "$HOME/.claude/skills" \
       "$HOME/.openclaw/workspace/skills"; do
       [ -n "$dir" ] && [ -f "$dir/lib/config.sh" ] && source "$dir/lib/config.sh" && break
     done 2>/dev/null
     load_pipeline_config "yt-transcript" 2>/dev/null || source ~/.config/content-pipeline/.env 2>/dev/null
     ```

3. **Run the extraction script**:
   ```bash
   for dir in \
     "." \
     "${CLAUDE_PLUGIN_ROOT:-}" \
     "$HOME/.claude/skills/yt-transcript" \
     "$HOME/.agents/skills/yt-transcript" \
     "$HOME/.codex/skills/yt-transcript"; do
     [ -n "$dir" ] && [ -f "$dir/scripts/extract.py" ] && SKILL_ROOT="$dir" && break
   done

   python3 "${SKILL_ROOT}/scripts/extract.py" "<URL>"
   ```
   Use a timeout of 120000ms (2 minutes).

4. **Save output** to `<output-dir>/transcript.md`

5. **Report results**:
   ```
   ✅ Transcript extracted: <title>
   📁 Saved to: <path>/transcript.md
   📊 ~<word-count> words | Duration: <duration>
   🔗 Source: <youtube-transcript-api or yt-dlp fallback>

   Next: Run `/content-summarizer <path>/transcript.md` to generate a structured summary.
   ```

## Error Handling

- **No captions available** → Report clearly: "This video has no captions/subtitles available (neither manual nor auto-generated)."
- **Invalid URL** → "Invalid YouTube URL. Please provide a valid youtube.com or youtu.be link."
- **Network error** → "Network error fetching transcript. Check your connection and try again."
