---
name: content-ideas
description: "Generate 5-10 content ideas with hooks, platforms, and image concepts from a content summary. Use after /content-summarizer."
argument-hint: 'content-ideas path/to/summary.md'
allowed-tools: Read, Write
---

# Content Ideas Generator

Generate actionable content ideas from a summary, each with a hook, target platform, and image concept.

## Execution Logic

Check `$ARGUMENTS`:
- If **empty** → respond: "Content Ideas loaded. Usage: `/content-ideas <path-to-summary.md>`" and STOP.
- If **has arguments** → treat as file path to summary and execute below.

## Task Execution

1. **Read the summary** at the path provided in `$ARGUMENTS`.

2. **Analyze the content** for:
   - Core themes and angles
   - Controversial or surprising points
   - Actionable advice
   - Relatable stories or analogies
   - Data points or statistics

3. **Generate 5-10 content ideas** with this format:

```markdown
---
source_title: "<from summary>"
source_url: "<from summary>"
date_generated: "<YYYY-MM-DD>"
type: content-ideas
---

# Content Ideas: <Source Title>

## Idea 1: <Title>
- **Hook:** [Opening line that grabs attention — first sentence someone reads]
- **Angle:** [What unique perspective or framing makes this interesting]
- **Platform:** [X | LinkedIn | Both | Blog | YouTube Short]
- **Category:** [Educational | Opinion | Story | How-To | Listicle | Thread]
- **Key points:**
  1. [Point 1]
  2. [Point 2]
  3. [Point 3]
- **Image concept:** [Describe an image that would pair well — style, composition, text overlay, mood. Be specific enough for an image generator.]
- **Image prompt suggestion:** [A refined prompt ready for Gemini/DALL-E: "Create a [style] image showing [subject] with [details], [mood/lighting], [aspect ratio suggestion]"]

## Idea 2: <Title>
[Same structure]

[Continue for 5-10 ideas]

---

## Quick Reference

| # | Title | Platform | Category | Image? |
|---|-------|----------|----------|--------|
| 1 | ... | X | Thread | Yes |
| 2 | ... | LinkedIn | Story | Yes |
[Table summary of all ideas]
```

4. **Save output** to the same directory as the summary, named `ideas.md`.

5. **Report results**:
```
✅ Content ideas generated: <N> ideas
📁 Saved to: <path>/ideas.md
📊 Platforms: <breakdown>

Next steps:
- `/social-posts <path>/ideas.md` — Generate ready-to-post social content
- `/tweet-generator <path>/ideas.md` — Generate tweet threads
- `/image-generator <path>/ideas.md` — Generate images for each idea
```

## Quality Rules
- Each idea must have a DIFFERENT angle — no overlapping content
- Hooks must be scroll-stopping, not generic
- Image concepts must be specific and actionable, not vague
- Platform choice should match content type (threads → X, long-form → LinkedIn)
- At least 2 ideas should be for X, at least 2 for LinkedIn
- At least 1 controversial/opinion piece, 1 educational, 1 story-based
