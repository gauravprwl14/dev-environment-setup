# tweet-generator

Generate 3-5 viral tweet threads from content ideas, each thread 5-12 tweets with character counts and image references.

## What it does

Takes a content ideas file and produces full tweet threads optimized for engagement on X. Each thread opens with a hook tweet, builds a narrative across 5-12 tweets using varied styles (statement, question, statistic, analogy, quote), and closes with a clear engagement CTA. Character counts are shown per tweet. Output includes a thread summary table for easy review before posting.

## How it works

This is an instruction-based skill. Claude generates the output directly — no scripts or external APIs required. Claude reads your ideas file, selects the best angles for thread format, and writes a `tweets.md` file using the Write tool.

## Usage

```
/tweet-generator path/to/ideas.md
```

Example:

```
/tweet-generator youtube-pipeline/my-video/ideas.md
```

Running the skill with no arguments prints usage instructions and stops.

## Input format

An `ideas.md` file (typically produced by `/content-ideas`) with YAML frontmatter and structured idea entries. Optionally, an `images/manifest.json` in the same directory for image pairing on the first tweet of each thread.

## Output format

A `tweets.md` file saved to the same directory as the input. Example structure:

```markdown
---
source: "How AI Is Changing Software Development"
date_generated: "2026-03-20"
type: tweet-threads
---

# Tweet Threads

## Thread 1: The Skill Shift Nobody Is Talking About
**Based on idea:** #1
**Thread image:** idea-1-split-screen.png
**Total tweets:** 7

### 1/ The hook
Most developers are optimizing for the wrong skill in 2026.

Here's what the top 1% figured out (and most devs haven't yet):
*(187/280)*

### 2/
It's not about writing faster code.

It's not about knowing more frameworks.

It's about writing better *intent*.
*(112/280)*

[continues...]

### 7/ CTA
Follow for more takes on where software engineering is actually heading.

Bookmark this thread — you'll want it when your team asks why AI changed your workflow.
*(198/280)*

**Thread stats:** 7 tweets | Avg 178 chars/tweet

## Thread Summary

| # | Title | Tweets | Avg Chars | Image? | Style |
|---|-------|--------|-----------|--------|-------|
| 1 | The Skill Shift... | 7 | 178 | ✅ | Opinion |
```

## Pipeline context

- **Receives from:** `/content-ideas` — an `ideas.md` file; optionally `/image-generator` — an `images/manifest.json`
- **Feeds into:** Your thread posting tool (Typefully, Buffer, or manual X posting) — copy threads directly from `tweets.md`

Typical pipeline: `/yt-transcript` → `/content-summarizer` → `/content-ideas` → `/tweet-generator`

## Tips

- Tweet 1 of each thread is the most important — it determines whether anyone reads the rest. If Claude's hook feels generic, ask it to rewrite tweet 1 with a more specific or controversial opening before accepting the thread.
- Character counts shown per tweet are Claude's best count — verify counts in Typefully or your scheduling tool before posting, as X counts some characters differently (URLs always count as 23 characters regardless of length).
- Threads work best at 6-9 tweets. Under 5 feels thin; over 12 loses readers. Ask Claude to trim or expand to hit your preferred length.
