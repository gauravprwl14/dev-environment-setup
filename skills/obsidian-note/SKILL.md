---
name: obsidian-note
description: "Create an Obsidian vault note from a content summary with wikilinks, callouts, tags, and frontmatter. Integrates with your Obsidian vault."
argument-hint: 'obsidian-note path/to/summary.md'
allowed-tools: Bash, Read, Write, Edit
---

# Obsidian Note Creator

Transform a content summary into an Obsidian-flavored note and save it to your vault.

## Execution Logic

Check `$ARGUMENTS`:
- If **empty** → respond: "Obsidian Note loaded. Usage: `/obsidian-note <path-to-summary.md>`" and STOP.
- If **has arguments** → treat as file path to summary and execute below.

## Configuration

Load environment:
```bash
# Load config (env var > shared .env > per-skill .env > defaults)
for dir in \
  "$(dirname "${SKILL_ROOT:-.}")" \
  "${CLAUDE_PLUGIN_ROOT:+${CLAUDE_PLUGIN_ROOT}/..}" \
  "$HOME/.claude/skills" \
  "$HOME/.openclaw/workspace/skills"; do
  [ -n "$dir" ] && [ -f "$dir/lib/config.sh" ] && source "$dir/lib/config.sh" && break
done 2>/dev/null
load_pipeline_config "obsidian-note" 2>/dev/null || source ~/.config/content-pipeline/.env 2>/dev/null
```

- Vault path: `$OBSIDIAN_VAULT_PATH` (default: `/home/ubuntu/home/project/gp/obsidian-vault/Ved`)
- Target folder: `content/yt-content/`

## BLOCKING REQUIREMENT

Before creating the note, read the Obsidian Vault Guide for vault conventions:
```
Read: ~/.openclaw/workspace/OBSIDIAN_VAULT_GUIDE.md
```

Also check if the obsidian-vault-guide skill has reference content loaded in this session.

## Task Execution

1. **Read the summary** at the path provided in `$ARGUMENTS`.

2. **Extract metadata** from summary frontmatter (title, channel, URL, themes).

3. **Generate Obsidian note** with these conventions:

```markdown
---
title: "<Title>"
channel: "[[<Channel Name>]]"
url: "<URL>"
date_created: <YYYY-MM-DD>
tags: [youtube, content, <topic-tags>]
type: yt-content
related: []
---

# <Title>

> [!info] Source
> **Channel:** [[<Channel Name>]]
> **URL:** [Watch on YouTube](<url>)
> **Duration:** <duration>

## Summary
[Condensed version of the thesis and key message]

## Key Insights

> [!tip] <Insight Title>
> [Key insight with context]

[Repeat for each major takeaway — use Obsidian callouts]

## Topics Covered
- [[<Topic 1>]] — brief note
- [[<Topic 2>]] — brief note
[Use wikilinks for ANY topic that could be its own note]

## Notable Quotes

> [!quote]
> "<Quote text>"

[Include top 3 quotes using Obsidian quote callouts]

## Connections
- Related to: [[<existing note>]], [[<concept>]]
- See also: [[<MOC or related note>]]

## Raw Notes
[Any additional details worth preserving]
```

4. **Save to vault**:
   - File name: `<YYYY-MM-DD>-<slug>.md` (slug from title, lowercase, hyphens)
   - Path: `$OBSIDIAN_VAULT_PATH/content/yt-content/<filename>`
   - Create the directory if it doesn't exist

5. **Update YouTube Content MOC**:
   - Check if `$OBSIDIAN_VAULT_PATH/content/yt-content/YouTube-Content-MOC.md` exists
   - If yes: append a link to the new note under the appropriate section
   - If no: create it with a header and the first link

6. **Report results**:
```
✅ Obsidian note created: <title>
📁 Saved to: <vault-path>/content/yt-content/<filename>
🔗 Wikilinks: <N> created
📋 MOC updated: YouTube-Content-MOC.md

Next: Open Obsidian to review, or run `/content-ideas <path>/summary.md`
```

## Obsidian Rules (from vault guide)
- ALWAYS use `[[Wikilink]]` syntax for internal references
- Use `> [!callout-type]` for callouts (tip, info, quote, warning)
- Include YAML frontmatter with tags, type, related
- Dense linking: every concept that could be its own note gets a wikilink
- If a referenced note doesn't exist, link it anyway (Obsidian handles forward references)
