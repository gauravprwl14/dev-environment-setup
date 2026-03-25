---
name: hashnode
description: Publish blog posts to Hashnode via GraphQL API with draft-first workflow. Always creates drafts; never auto-publishes. Supports full markdown content with sections, images, code blocks, tags, series, SEO metadata, and cover images. Use when user needs to create drafts on Hashnode or explicitly publish existing drafts.
---

# Hashnode Publishing Skill

Automate Hashnode blog posting with a **draft-first workflow**. All posts are created as drafts by default. Publishing requires explicit user action.

## Prerequisites

Set these environment variables in your workspace `.env`:

```bash
HASHNODE_API_KEY=your-personal-access-token
HASHNODE_PUBLICATION_ID=your-publication-id
```

**Getting credentials:**
- **API Key:** Hashnode → Account Settings → Developer → Generate new token
- **Publication ID:** Your blog dashboard URL: `hashnode.com/{PUBLICATION_ID}/dashboard`

## Usage

### Step 1: Create a Draft

```bash
cd "$(dirname "${CLAUDE_PLUGIN_ROOT:-$HOME/.agents/skills/hashnode}")/scripts" 2>/dev/null || true
node create-draft.js /path/to/article.md
```

This **always creates a draft** (never publishes).

### Step 2: Publish Draft (Explicit)

```bash
# List all drafts
node publish-existing-draft.js

# Publish specific draft by slug
node publish-existing-draft.js my-article-slug

# Or by draft ID
node publish-existing-draft.js 63a5f2b8e1c4d9001a234567
```

**Safety:** Requires user confirmation before publishing.

### Expected markdown format

The markdown file should have YAML front-matter:

```markdown
---
title: Your Article Title
subtitle: Optional subtitle
brief: Short SEO description (recommended)
coverImage: https://cdn.example.com/cover.png
tags: nodejs,typescript,fintech
canonical: https://yoursite.com/original-post
---

## Introduction

Your content here with full markdown support...

## Section with code

\```typescript
const example = "Full code blocks supported";
\```

## Inline images

![Alt text](https://cdn.example.com/image.png)
```

**Note:** The `publish` field is **no longer used**. All drafts must be published explicitly.

### Programmatic usage

```javascript
import { publishToHashnode } from './scripts/publish-post.js';
import { publishDraft } from './scripts/hashnode-client.js';

// Step 1: Create draft
const draft = await publishToHashnode({
  title: 'My Article Title',
  contentMarkdown: '## Introduction\n\nFull markdown content...',
  subtitle: 'Optional subtitle',
  brief: 'SEO description',
  coverImageURL: 'https://cdn.example.com/cover.png',
  tags: [
    { id: '56744723958ef13879b951ef', slug: 'nodejs', name: 'Node.js' }
  ],
  slug: 'custom-url-slug',
  canonicalURL: 'https://yoursite.com/original',
});

console.log('Draft created:', draft.id, draft.slug);

// Step 2: Publish explicitly
const post = await publishDraft(draft.id);
console.log('Published:', post.url);
```

## Features

- ✅ **Draft-first workflow** (never auto-publishes)
- ✅ Full markdown support (headings, code blocks, images, tables)
- ✅ Explicit publish with user confirmation
- ✅ Tags, series, and SEO metadata
- ✅ Cover images
- ✅ Custom URL slugs
- ✅ Canonical URLs for cross-posting
- ✅ Error handling with retry logic
- ✅ Publish action logging

## Tag Reference

Common tag IDs (see `references/tag-ids.md` for full list):
- Node.js: `56744723958ef13879b951ef`
- JavaScript: `56744721958ef13879b94cad`
- TypeScript: `5cd9f71d8d7b4e53b5e6dde6`
- NestJS: `5f64a67e8d5a87bfb3f74625`

## Files

- `scripts/hashnode-client.js` - Core GraphQL API client with draft management
- `scripts/publish-post.js` - Main draft creation function
- `scripts/create-draft.js` - CLI wrapper for creating drafts from markdown
- `scripts/publish-existing-draft.js` - CLI for publishing existing drafts
- `references/api-reference.md` - Full GraphQL API documentation
- `references/tag-ids.md` - Hashnode tag ID lookup
- `references/examples.md` - Usage examples

## Notes

- All mutations require authentication via PAT
- **Default behavior: DRAFT ONLY** - never auto-publishes
- Cover images must be publicly accessible URLs
- Tags require both ID and slug (use tag lookup query)
- Publishing requires explicit user command + confirmation
- All publish actions logged to `~/.config/content-pipeline/logs/hashnode-publish-log.json` (override with `CONTENT_PIPELINE_LOG_DIR` env var)
- Supports GitHub Flavored Markdown (GFM)

## Safety Features

1. **Draft-first:** No accidental publishing
2. **Confirmation prompt:** User must confirm before publish
3. **Action logging:** All publishes tracked with timestamp
4. **List drafts:** Easy review before publishing
