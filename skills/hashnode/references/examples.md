# Hashnode Skill Usage Examples

## Draft-First Workflow

All examples now follow the **draft → publish** workflow. No posts are auto-published.

---

## Example 1: Create Draft + Publish

**Step 1: Create draft**

**Input file: `my-post.md`**

```markdown
---
title: Getting Started with NestJS
subtitle: A modern Node.js framework for building scalable server-side applications
brief: Learn the basics of NestJS, a progressive Node.js framework built with TypeScript.
coverImage: https://cdn.example.com/nestjs-cover.png
tags: nestjs,nodejs,typescript
---

## Introduction

NestJS is a framework for building efficient, scalable Node.js server-side applications.

## Installation

\```bash
npm install -g @nestjs/cli
nest new my-project
\```

## Creating Your First Controller

\```typescript
import { Controller, Get } from '@nestjs/common';

@Controller('cats')
export class CatsController {
  @Get()
  findAll(): string {
    return 'This action returns all cats';
  }
}
\```

## Conclusion

NestJS makes it easy to build production-ready APIs with TypeScript.
```

**Command:**

```bash
cd /home/ubuntu/Sites/projects/gp/dev-environment-setup/skills/hashnode/scripts
node create-draft.js ../examples/my-post.md
```

**Output:**

```
📖 Reading file: /path/to/my-post.md
🏷️ Resolving 3 tag(s)...
🔍 Looking up tag: "nestjs"...
✅ Found tag: NestJS (5f64a67e8d5a87bfb3f74625)
🔍 Looking up tag: "nodejs"...
✅ Found tag: Node.js (56744723958ef13879b951ef)
🔍 Looking up tag: "typescript"...
✅ Found tag: TypeScript (5cd9f71d8d7b4e53b5e6dde6)

🚀 Creating draft on Hashnode...
   Title: Getting Started with NestJS
   Tags: NestJS, Node.js, TypeScript

📝 Creating draft: "Getting Started with NestJS"...
✅ Draft created successfully!
   Draft ID: abc123xyz
   Slug: getting-started-with-nestjs
   Title: Getting Started with NestJS

📌 Draft saved (not published)
   To publish: node publish-existing-draft.js getting-started-with-nestjs

✅ Success!
📊 Result: {
  "id": "abc123xyz",
  "slug": "getting-started-with-nestjs",
  "title": "Getting Started with NestJS",
  "isDraft": true,
  "url": "https://hashnode.com/draft/abc123xyz"
}

🔗 View at: https://hashnode.com/draft/abc123xyz
```

**Step 2: Publish draft**

```bash
node publish-existing-draft.js getting-started-with-nestjs
```

**Output:**

```
🔍 Looking for draft: "getting-started-with-nestjs"...
✅ Found draft: "Getting Started with NestJS"
   Draft ID: abc123xyz
   Slug: getting-started-with-nestjs

Publish draft "Getting Started with NestJS" to Hashnode? (y/N): y

🚀 Publishing draft...

✅ Published successfully!
   Title: Getting Started with NestJS
   URL: https://yourblog.hashnode.dev/getting-started-with-nestjs
   Slug: getting-started-with-nestjs

📋 Logged to: /home/ubuntu/.openclaw/workspace/hashnode-publish-log.json
🔗 View at: https://yourblog.hashnode.dev/getting-started-with-nestjs
```

---

## Example 2: List Drafts

**Command:**

```bash
node publish-existing-draft.js
```

**Output:**

```
📋 Fetching drafts...

Found 3 draft(s):

1. Getting Started with NestJS
   Slug: getting-started-with-nestjs
   ID: abc123xyz
   Updated: 3/10/2026, 8:45:30 PM

2. Advanced System Design Patterns
   Slug: advanced-system-design-patterns
   ID: def456uvw
   Updated: 3/9/2026, 2:15:00 PM

3. Building REST APIs with NestJS
   Slug: building-rest-apis-nestjs
   ID: ghi789rst
   Updated: 3/8/2026, 10:30:45 AM

To publish a draft:
  node publish-existing-draft.js <slug-or-id>
```

---

## Example 3: Cross-Posting with Canonical URL

**Input file: `cross-post.md`**

```markdown
---
title: How We Built Our NAO Platform
subtitle: Architecture lessons from building a multi-tenant fintech system
brief: Technical deep-dive into building a production-ready New Account Opening platform.
coverImage: https://yourblog.com/images/nao-architecture.png
tags: fintech,nestjs,architecture,typescript
canonical: https://yourblog.com/blog/nao-platform
---

## Original Article

This article was originally published on [my blog](https://yourblog.com/blog/nao-platform).

## Introduction

When we set out to build a New Account Opening platform...
```

**Commands:**

```bash
# Create draft
node create-draft.js cross-post.md

# Review draft on Hashnode dashboard, then publish
node publish-existing-draft.js how-we-built-our-nao-platform
```

This sets the canonical URL to point to your original blog, telling search engines that's the primary source.

---

## Example 4: Programmatic Publishing (Two-Step)

**Script: `batch-publish.js`**

```javascript
import { publishToHashnode } from './scripts/publish-post.js';
import { publishDraft } from './scripts/hashnode-client.js';

const posts = [
  {
    title: 'Understanding TypeScript Generics',
    contentMarkdown: '## Introduction\n\nGenerics in TypeScript...',
    brief: 'Master TypeScript generics with practical examples.',
    tags: [
      { id: '5cd9f71d8d7b4e53b5e6dde6', slug: 'typescript', name: 'TypeScript' }
    ],
  },
  {
    title: 'Building REST APIs with NestJS',
    contentMarkdown: '## Getting Started\n\nNestJS makes it easy...',
    brief: 'Learn how to build production-ready REST APIs.',
    tags: [
      { id: '5f64a67e8d5a87bfb3f74625', slug: 'nestjs', name: 'NestJS' },
      { id: '56744723958ef13879b951ef', slug: 'nodejs', name: 'Node.js' }
    ],
  }
];

// Step 1: Create all drafts
const drafts = [];
for (const post of posts) {
  console.log(`\n📝 Creating draft: ${post.title}`);
  const draft = await publishToHashnode(post);
  drafts.push(draft);
  console.log(`✅ Draft created: ${draft.slug}`);
  
  // Rate limiting: wait 2 seconds between requests
  await new Promise(r => setTimeout(r, 2000));
}

// Step 2: Review drafts manually, then publish programmatically if desired
console.log('\n\n📋 Created drafts:');
drafts.forEach(d => console.log(`  - ${d.slug} (ID: ${d.id})`));

console.log('\n⚠️ Review drafts on Hashnode before publishing!');

// Optional: Publish specific drafts programmatically (uncomment to use)
// const postToPublish = drafts[0];
// const published = await publishDraft(postToPublish.id);
// console.log(`\n✅ Published: ${published.url}`);
```

---

## Example 5: Rich Content with Images and Code

**Input file: `tutorial.md`**

```markdown
---
title: Complete Guide to React Hooks
subtitle: From basics to advanced patterns
brief: Master React Hooks with real-world examples and best practices.
coverImage: https://cdn.example.com/react-hooks.png
tags: reactjs,javascript,frontend,tutorial
---

## Introduction

React Hooks revolutionized how we write React components.

## useState Hook

The most commonly used hook for managing component state.

\```jsx
import { useState } from 'react';

function Counter() {
  const [count, setCount] = useState(0);
  
  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  );
}
\```

## Visual Example

![React Hooks Flow](https://cdn.example.com/hooks-flow.png)
*Figure 1: React component lifecycle with hooks*

## useEffect Hook

\```jsx
import { useEffect, useState } from 'react';

function DataFetcher() {
  const [data, setData] = useState(null);
  
  useEffect(() => {
    fetch('/api/data')
      .then(res => res.json())
      .then(setData);
  }, []); // Empty deps = run once
  
  return <div>{JSON.stringify(data)}</div>;
}
\```

## Best Practices

| Rule | Description |
|------|-------------|
| Call at top level | Don't call inside loops or conditions |
| Use ESLint plugin | Install `eslint-plugin-react-hooks` |
| Deps array | Always specify dependencies |

## Conclusion

Hooks make React code more reusable and easier to understand.
```

This produces a fully-formatted article with:
- Code blocks with syntax highlighting
- Inline images with captions
- Tables
- Proper heading hierarchy
- Table of contents (auto-generated)

---

## Example 6: Agent-Triggered Workflow

**Workflow:**

1. Agent writes blog post to workspace: `~/workspace/blog-drafts/my-post.md`
2. Agent creates draft:

```javascript
// Agent reasoning: "User asked me to draft the fintech article"

const result = await exec({
  command: 'node create-draft.js /home/ubuntu/.openclaw/workspace/blog-drafts/fintech-platform.md',
  workdir: '/home/ubuntu/Sites/projects/gp/dev-environment-setup/skills/hashnode/scripts'
});

// Agent responds: "Draft created: fintech-platform. Review it before publishing."
```

3. User reviews draft on Hashnode dashboard
4. User says: "Publish the fintech-platform draft"
5. Agent publishes:

```javascript
const publishResult = await exec({
  command: 'echo "y" | node publish-existing-draft.js fintech-platform',
  workdir: '/home/ubuntu/Sites/projects/gp/dev-environment-setup/skills/hashnode/scripts'
});

// Agent responds: "Published to Hashnode: [URL]"
```

**Important:** Agents should NEVER auto-publish without explicit user instruction.

---

## Example 7: Series Support

When you have multiple related posts, group them into a series.

**First, create a series in Hashnode dashboard:**
1. Go to your publication settings
2. Create a new series: "NestJS Tutorials"
3. Note the series ID from the URL

**Then reference it in posts:**

```markdown
---
title: NestJS Part 1 - Getting Started
brief: Introduction to NestJS framework
tags: nestjs,nodejs
seriesId: your-series-id-here
---

This is the first post in the NestJS tutorial series...
```

**Create and publish:**

```bash
node create-draft.js nestjs-part-1.md
node publish-existing-draft.js nestjs-part-1-getting-started
```

---

## Error Handling Example

```javascript
import { publishWithRetry } from './scripts/publish-post.js';

try {
  const draft = await publishWithRetry({
    title: 'My Post',
    contentMarkdown: '## Content...',
    tags: [
      { id: 'invalid-id', slug: 'fake', name: 'Fake' }
    ]
  }, 3); // Retry up to 3 times
  
  console.log('Draft created:', draft.id, draft.slug);
} catch (err) {
  console.error('Failed after retries:', err.message);
  // Handle failure (notify user, save for later, etc.)
}
```

---

## Common Workflows

### Workflow 1: Draft → Review → Publish
1. Write post in markdown
2. Run `node create-draft.js post.md` → creates draft
3. Review on Hashnode dashboard
4. Run `node publish-existing-draft.js <slug>` → publishes

### Workflow 2: Agent-Assisted Writing
1. User: "Write a blog post about NestJS"
2. Agent: Researches, writes markdown, saves to workspace
3. Agent: Runs `create-draft.js` with tags/metadata
4. Agent: Reports draft created, waits for publish command
5. User: "Publish it"
6. Agent: Runs `publish-existing-draft.js` (with confirmation)

### Workflow 3: Batch Draft Creation
1. Write multiple posts in `content/` directory
2. Loop through files and create drafts
3. Review all drafts on Hashnode
4. Selectively publish approved drafts

---

## Tips

1. **Always review drafts first** - Check formatting, images, links
2. **Use valid tag IDs** - Reference `references/tag-ids.md` or search via API
3. **Set brief for SEO** - 160 characters, compelling summary
4. **Cover images boost clicks** - Use high-quality, relevant images
5. **Custom slugs for SEO** - Use descriptive URLs like `nestjs-dependency-injection`
6. **Canonical URLs matter** - Set when cross-posting to preserve SEO
7. **Check publish log** - Review `~/.openclaw/workspace/hashnode-publish-log.json` for history

---

## Safety Checklist

✅ All posts created as drafts by default  
✅ Confirmation required before publishing  
✅ All publish actions logged with timestamp  
✅ Easy draft listing and review  
✅ No accidental publishes  
