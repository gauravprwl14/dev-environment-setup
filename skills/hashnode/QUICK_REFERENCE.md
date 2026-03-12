# Hashnode Skill Quick Reference

## 🚀 Quick Start

### Setup (One-Time)
```bash
# Add to ~/.openclaw/workspace/.env or skill directory:
HASHNODE_API_KEY=your-token-here
HASHNODE_PUBLICATION_ID=your-pub-id-here
```

## 📝 Common Commands

### Create Draft
```bash
cd /home/ubuntu/Sites/projects/gp/dev-environment-setup/skills/hashnode/scripts
node create-draft.js ../path/to/article.md
```

### List All Drafts
```bash
node publish-existing-draft.js
```

### Publish Draft
```bash
node publish-existing-draft.js <slug-or-id>
# Confirm with 'y' when prompted
```

### View Publish History
```bash
cat ~/.openclaw/workspace/hashnode-publish-log.json
```

## 📄 Front-Matter Template

```markdown
---
title: Your Article Title
subtitle: Optional subtitle
brief: SEO description (160 chars max)
coverImage: https://cdn.example.com/cover.png
tags: nodejs,typescript,fintech
canonical: https://yoursite.com/original
seriesId: optional-series-id
---

Your markdown content here...
```

## 🤖 Agent Usage

### Creating Drafts
```javascript
// SAFE: Always creates draft, never publishes
await exec({
  command: 'node create-draft.js /path/to/article.md',
  workdir: '/home/ubuntu/Sites/projects/gp/dev-environment-setup/skills/hashnode/scripts'
});
```

### Publishing (EXPLICIT ONLY)
```javascript
// Only when user explicitly says "publish draft X"
// Uses echo "y" to auto-confirm (use with caution!)
await exec({
  command: 'echo "y" | node publish-existing-draft.js article-slug',
  workdir: '/home/ubuntu/Sites/projects/gp/dev-environment-setup/skills/hashnode/scripts'
});
```

## 🔒 Safety Rules

1. **NEVER auto-publish** - Always create draft first
2. **Explicit publish only** - User must say "publish draft X"
3. **Confirmation required** - Interactive prompt or echo pipe
4. **Review first** - Encourage user to check draft on Hashnode
5. **Log all actions** - Check publish-log.json for audit trail

## 🎯 Workflow

```
1. Write article → 2. Create draft → 3. Review → 4. Publish
   (markdown)        (create-draft)    (manual)   (publish-existing-draft)
```

## 📚 Key Files

- `create-draft.js` - Create draft from markdown
- `publish-existing-draft.js` - Publish existing draft
- `hashnode-client.js` - API client functions
- `publish-post.js` - Core draft creation logic

## 🐛 Troubleshooting

**"Missing HASHNODE_API_KEY"**
→ Add credentials to `.env` file

**"Draft not found"**
→ Run `node publish-existing-draft.js` to list available drafts

**"Tag not found"**
→ Check tag spelling, Hashnode uses exact tag names

**Syntax error in markdown**
→ Validate YAML front-matter (check colons, quotes, indentation)

## 📖 Full Documentation

- `SKILL.md` - Complete usage guide
- `references/examples.md` - Detailed examples
- `UPDATE_SUMMARY.md` - Change log
- `VERIFICATION_REPORT.md` - Test results
