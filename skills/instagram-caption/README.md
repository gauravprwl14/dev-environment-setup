# instagram-caption

Generate a scroll-stopping Instagram caption from `blog.md` and save it to `instagram.md`.

## Usage

```
/instagram-caption path/to/blog.md
```

## What it does

Reads `blog.md` and writes `instagram.md` to the same directory. The output includes a hook opening line, value-rich body, and a call-to-action with hashtags.

**Caption structure:**
- Hook (first line — visible before "more" fold)
- 3–5 insight lines with line breaks for readability
- Call to action
- 20–30 relevant hashtags

**Output format:**
```markdown
# Instagram Caption

---

[Hook line that stops the scroll]

[Insight 1]
[Insight 2]
[Insight 3]

[CTA]

---

#hashtag1 #hashtag2 ... #hashtag25
```

## Character limit

Instagram captions allow up to 2,200 characters. The skill targets 800–1,200 characters for the caption body (before hashtags).

## Pipeline position

```
/blog-generator → blog.md → /instagram-caption → instagram.md
```

## Requirements

No API keys, no scripts — pure Claude generation.
