# Hashnode Publishing Skill

Automate blog post publishing to Hashnode using the GraphQL API.

## Quick Start

### 1. Install Dependencies

```bash
cd scripts/
npm install
```

### 2. Configure Credentials

Copy `.env.example` to your workspace `.env` and fill in:

```bash
HASHNODE_API_KEY=your-personal-access-token
HASHNODE_PUBLICATION_ID=your-publication-id
```

**Get your credentials:**
- API Key: Hashnode → Account Settings → Developer → Generate new token
- Publication ID: Dashboard URL → `hashnode.com/{PUBLICATION_ID}/dashboard`

### 3. Publish a Post

```bash
cd scripts/
node publish-draft.js /path/to/your-article.md
```

## Directory Structure

```
hashnode/
├── SKILL.md                      # Agent instructions (loaded by OpenClaw)
├── README.md                     # This file
├── .env.example                  # Environment template
├── test-article.md              # Example markdown file
├── scripts/
│   ├── package.json
│   ├── hashnode-client.js       # Core GraphQL API client
│   ├── publish-post.js          # Publishing logic
│   └── publish-draft.js         # CLI wrapper (main entry point)
└── references/
    ├── api-reference.md         # Full GraphQL API docs
    ├── tag-ids.md               # Common Hashnode tag IDs
    └── examples.md              # Usage examples
```

## Markdown Format

Articles should have YAML front-matter:

```markdown
---
title: Your Article Title
subtitle: Optional subtitle
brief: Short SEO description (recommended)
coverImage: https://cdn.example.com/cover.png
tags: nodejs,typescript,fintech
canonical: https://yoursite.com/original-post
publish: true
---

## Your Content Here

Full markdown support including:
- Headings
- Code blocks with syntax highlighting
- Images
- Tables
- Lists
```

## Features

- ✅ Full GitHub Flavored Markdown support
- ✅ Draft → Publish workflow (safer for automation)
- ✅ Automatic tag ID resolution
- ✅ Cover images and SEO metadata
- ✅ Custom URL slugs
- ✅ Canonical URLs for cross-posting
- ✅ Series support
- ✅ Retry logic with exponential backoff
- ✅ Detailed error messages

## Agent Usage

When the OpenClaw agent needs to publish to Hashnode:

```javascript
// The agent will automatically:
// 1. Read the SKILL.md file
// 2. Execute the publish-draft.js script
// 3. Report the published URL back to the user
```

## Programmatic Usage

Import and use directly in Node.js:

```javascript
import { publishToHashnode } from './scripts/publish-post.js';

const result = await publishToHashnode({
  title: 'My Article',
  contentMarkdown: '## Introduction\n\nYour content here...',
  brief: 'Article description',
  tags: [
    { id: '56744723958ef13879b951ef', slug: 'nodejs', name: 'Node.js' }
  ],
  publish: true
});

console.log(`Published: ${result.url}`);
```

## Testing

Test without publishing (creates draft only):

```bash
node publish-draft.js test-article.md
```

This creates a draft on Hashnode but doesn't publish it. Check your drafts dashboard to verify.

## Documentation

- **SKILL.md** - Concise instructions for OpenClaw agents
- **references/api-reference.md** - Full GraphQL API documentation
- **references/tag-ids.md** - Common Hashnode tag IDs lookup
- **references/examples.md** - Detailed usage examples

## Requirements

- Node.js 18+ (for native `fetch` support)
- Hashnode account with API access
- Valid Personal Access Token
- Publication ID

## Troubleshooting

### "Missing HASHNODE_API_KEY"
- Ensure `.env` file exists in workspace root
- Check the API key is valid (test in GraphQL playground)

### "Tag not found"
- Use tag names that exist on Hashnode
- Check `references/tag-ids.md` for common tags
- Search for tags using the API before publishing

### "Publication not found"
- Verify your publication ID from dashboard URL
- Ensure the API key has access to that publication

### "HTTP 401 Unauthorized"
- Your API token is invalid or expired
- Regenerate a new token from Hashnode settings

## Contributing

To improve this skill:

1. Update relevant files in `scripts/` or `references/`
2. Keep `SKILL.md` concise (<2K tokens)
3. Add examples to `references/examples.md`
4. Update tag IDs in `references/tag-ids.md` as needed

## Resources

- [Hashnode GraphQL API Docs](https://docs.hashnode.com/quickstart/hashnode-graphql-api-quickstart)
- [GraphQL Playground](https://gql.hashnode.com)
- [Hashnode Developer Settings](https://hashnode.com/settings/developer)

## License

MIT
