---
name: obsidian-vault-guide
user-invocable: false
description: "Background knowledge skill encoding Obsidian vault structure, naming conventions, wikilink rules, and graph growth principles. Referenced by obsidian-note skill."
---

# Obsidian Vault Guide — Background Knowledge

This skill provides vault conventions for other skills that write to the Obsidian vault. It is NOT user-invocable.

## Vault Location

`$OBSIDIAN_VAULT_PATH` → default: `/home/ubuntu/Sites/projects/gp/obsidian-vault/Ved/`

## Vault Structure

```
Ved/
├── daily/                    # Daily notes (YYYY-MM-DD.md)
├── memory/                   # Curated insights from daily notes
├── projects/                 # Active projects
├── content/                  # Content creation workspace
│   ├── topics/               # Ideas & drafts
│   └── yt-content/           # YouTube content (THIS IS WHERE YT NOTES GO)
├── blogs/                    # Published blog posts
├── resources/                # Reference materials
│   ├── engineering/
│   ├── skills/
│   └── tools/
├── systems/                  # Automation & SOPs
├── tasks/                    # Active to-dos
└── templates/                # Note templates
```

## Naming Conventions

- **Daily notes:** `YYYY-MM-DD.md`
- **YT content notes:** `YYYY-MM-DD-slug.md`
- **Blog posts:** `YYYY-MM-DD-title.md`
- **MOCs:** `Topic-Name-MOC.md`
- **Templates:** `templates/template-name.md`

## Wikilink Rules (CRITICAL)

- **ALWAYS** use `[[Wikilink]]` syntax for internal references
- Link ANY concept that could be its own note: tools, technologies, people, projects
- If referenced note doesn't exist → link it anyway (Obsidian handles forward references)
- Use `[[Note Title|Display Text]]` when the link text should differ from note title
- Goal: maximize graph connectivity with every note created

## Frontmatter Template

```yaml
---
title: "Note Title"
tags: [tag1, tag2, tag3]
type: yt-content | memory | project | resource
date_created: YYYY-MM-DD
related: ["[[Related Note 1]]", "[[Related Note 2]]"]
---
```

## Callout Syntax

```markdown
> [!info] Title
> Content

> [!tip] Title
> Content

> [!quote]
> "Quote text"

> [!warning] Title
> Content
```

## MOC (Map of Content) Pattern

YouTube Content MOC at `content/yt-content/YouTube-Content-MOC.md`:
```markdown
---
title: YouTube Content MOC
tags: [moc, youtube, content]
type: moc
---

# YouTube Content MOC

## Recent
- [[YYYY-MM-DD-slug]] — Brief description

## By Topic
### <Topic>
- [[note-1]]
- [[note-2]]
```

## Graph Growth Principles
1. Every note MUST link to at least 2 other notes
2. When creating a note about a topic, check if a MOC exists → add to it
3. Prefer wikilinks over plain text for ANY proper noun, tool name, or concept
4. Create bidirectional links where possible
5. Tag notes for discoverability (#youtube, #content, #topic-name)
