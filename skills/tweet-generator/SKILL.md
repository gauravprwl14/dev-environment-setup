---
name: tweet-generator
description: "Generate 3-5 viral tweet threads from content ideas. Each thread is 5-12 tweets with character counts and image references."
argument-hint: 'tweet-generator path/to/ideas.md'
allowed-tools: Read, Write
---

# Tweet Thread Generator

Generate viral tweet threads from content ideas, optimized for engagement.

## Execution Logic

Check `$ARGUMENTS`:
- If **empty** → respond: "Tweet Generator loaded. Usage: `/tweet-generator <path-to-ideas.md>`" and STOP.
- If **has arguments** → treat as file path to ideas file and execute below.

## Task Execution

1. **Read the ideas file** at the path provided in `$ARGUMENTS`.

2. **Check for images manifest**: Look for `images/manifest.json` in the same directory for image pairing.

3. **Generate 3-5 tweet threads**, each 5-12 tweets:

```markdown
---
source: "<from ideas.md>"
date_generated: "<YYYY-MM-DD>"
type: tweet-threads
---

# Tweet Threads

## Thread 1: <Title>
**Based on idea:** #<idea-number>
**Thread image:** <image ref for first tweet>
**Total tweets:** <N>

### 1/ <First tweet — the hook>
[Tweet text]
*(<char count>/280)*

### 2/ <Second tweet>
[Tweet text]
*(<char count>/280)*

### 3/ <Third tweet>
[Tweet text]
*(<char count>/280)*

[Continue...]

### <N>/ <Final tweet — CTA>
[Tweet text — end with engagement CTA: follow, retweet, bookmark]
*(<char count>/280)*

**Thread stats:** <N> tweets | Avg <N> chars/tweet

---

## Thread 2: <Title>
[Same structure]

---

[Continue for 3-5 threads]

## Thread Summary

| # | Title | Tweets | Avg Chars | Image? | Style |
|---|-------|--------|-----------|--------|-------|
| 1 | ... | 8 | 210 | ✅ | Educational |
| 2 | ... | 6 | 245 | ✅ | Story |
```

4. **Save output** to the same directory as the ideas file, named `tweets.md`.

5. **Report results**:
```
✅ Tweet threads generated: <N> threads
📁 Saved to: <path>/tweets.md
📊 Total tweets: <N> | Avg thread length: <N>
🖼️ Images referenced: <N>

Tip: Post threads using Typefully, Buffer, or manually via X.
```

## Quality Rules
- Every tweet should be under 280 characters — Claude will count each one carefully, but verify counts in your scheduling tool before posting (X counts URLs as 23 characters regardless of length)
- Tweet 1/ is EVERYTHING — must hook immediately
- Each tweet should standalone but flow as a narrative
- Use numbered format: 1/, 2/, 3/ etc.
- Vary tweet styles: statement, question, statistic, analogy, quote
- Final tweet = engagement CTA (follow for more, bookmark this, RT if useful)
- NO hashtags in thread tweets (they reduce reach on X)
- Use line breaks within tweets for readability
- 3-5 threads with different angles on the same content
