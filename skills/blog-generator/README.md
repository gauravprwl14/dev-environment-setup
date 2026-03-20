# blog-generator

Generate a complete, publication-ready blog post from a `summary.md`. The resulting `blog.md` is the master content asset — carousels, Instagram captions, and social posts all derive from it.

## Usage

```
/blog-generator path/to/summary.md
```

## What it does

Reads `summary.md` (produced by `/content-summarizer`) and writes a full blog post to `blog.md` in the same directory. The post is structured for Hashnode, dev.to, or any markdown-based blog platform.

**Output structure:**
```markdown
---
title: "..."
date: YYYY-MM-DD
tags: [...]
canonical_url: ""
---

# Title

## Introduction
...

## Section 1: Key Insight
...

## Conclusion
...
```

## Pipeline position

```
/content-summarizer → summary.md → /blog-generator → blog.md
                                                         ↓
                                      /carousel-generator → carousel.md
                                      /instagram-caption  → instagram.md
                                      /social-posts       → social-posts.md
```

## Requirements

No API keys, no scripts — pure Claude generation.

## Next steps after running

```
/carousel-generator path/to/blog.md
/instagram-caption  path/to/blog.md
/hashnode           path/to/blog.md
```
