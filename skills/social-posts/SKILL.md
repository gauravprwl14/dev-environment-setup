---
name: social-posts
description: "Generate platform-ready social media posts (X and LinkedIn) paired with images from content ideas. Use after /content-ideas."
argument-hint: 'social-posts path/to/ideas.md'
allowed-tools: Read, Write
---

# Social Posts Generator

Generate ready-to-post social media content for X and LinkedIn, each paired with an image reference.

## Execution Logic

Check `$ARGUMENTS`:
- If **empty** → respond: "Social Posts loaded. Usage: `/social-posts <path-to-ideas.md>`" and STOP.
- If **has arguments** → treat as file path to ideas file and execute below.

## Task Execution

1. **Read the ideas file** at the path provided in `$ARGUMENTS`.

2. **Check for images manifest**: Look for `images/manifest.json` in the same directory. If it exists, read it to pair posts with generated images.

3. **Generate social posts** for each content idea:

```markdown
---
source: "<from ideas.md>"
date_generated: "<YYYY-MM-DD>"
type: social-posts
---

# Social Posts

## X Posts

### Post 1: <Idea Title>
**From idea:** #<idea-number>
**Image:** <image filename from manifest, or "Generate with /image-generator">

<Post text — max 280 characters. Punchy, direct, no fluff.>

---

### Post 2: <Idea Title>
**From idea:** #<idea-number>
**Image:** <image ref>

<Post text>

---

[Continue for each X-suitable idea]

## LinkedIn Posts

### Post 1: <Idea Title>
**From idea:** #<idea-number>
**Image:** <image ref>

<Post text — 150-300 words. Professional tone, storytelling structure.>

**Structure:**
- Hook (first line visible before "see more")
- Story/context (2-3 paragraphs)
- Key insight or lesson
- Call to action or question
- Hashtags (3-5 relevant)

---

[Continue for each LinkedIn-suitable idea]

## Post Calendar

| # | Platform | Title | Chars/Words | Image Ready? |
|---|----------|-------|-------------|-------------|
| 1 | X | ... | 247 chars | ✅/❌ |
| 2 | LinkedIn | ... | 230 words | ✅/❌ |
```

4. **Save output** to the same directory as the ideas file, named `social-posts.md`.

5. **Report results**:
```
✅ Social posts generated
📁 Saved to: <path>/social-posts.md
📊 X posts: <N> | LinkedIn posts: <N>
🖼️ Images paired: <N>/<total>

Next: Copy posts to your scheduling tool, or run `/tweet-generator <path>/ideas.md` for threads.
```

## Quality Rules for X Posts
- MUST be under 280 characters (count precisely)
- Lead with the hook — no preamble
- Use line breaks for readability
- No hashtags in X posts (they reduce reach)
- End with engagement driver (question, bold claim, or "RT if you agree")

## Quality Rules for LinkedIn Posts
- First line MUST be a scroll-stopper (it shows before "see more")
- 150-300 words optimal
- Use short paragraphs (1-2 sentences each)
- Include 3-5 hashtags at the end
- End with a question to drive comments
- Professional but not corporate — conversational tone
