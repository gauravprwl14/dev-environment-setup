# carousel-generator

Generate a structured 8–12 slide carousel from `blog.md`. Output is copy-paste ready for Canva, Google Slides, Figma, or Gemini.

## Usage

```
/carousel-generator path/to/blog.md
```

## What it does

Reads `blog.md` and writes `carousel.md` to the same directory. The output contains fully written slide content — headline, body text, and design notes — for each slide.

**Slide structure:**
- Slide 1: Hook / Cover (attention-grabbing opening)
- Slides 2–N: One key insight per H2 section from the blog
- Second-to-last: Actionable takeaway
- Last: CTA (follow / save / comment)

**Output format:**
```markdown
## Slide 1 — Cover
**Headline:** ...
**Subheadline:** ...
*Design note: Bold text on dark background*

## Slide 2 — Insight 1
**Headline:** ...
**Body:** ...
*Design note: ...*
```

## Pipeline position

```
/blog-generator → blog.md → /carousel-generator → carousel.md
```

## Requirements

No API keys, no scripts — pure Claude generation.

## Designed for

LinkedIn carousels, Instagram slideshows, Canva decks, Google Slides presentations.
