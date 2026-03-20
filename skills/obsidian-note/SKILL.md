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

### Vault Path Resolution

Resolve the vault path using this priority order:

1. If the environment variable `OBSIDIAN_VAULT_PATH` is set → use it.
2. Otherwise fall back to the default: `/home/ubuntu/Sites/projects/gp/obsidian-vault/Ved`.

After resolving, verify the directory exists:
```bash
VAULT_PATH="${OBSIDIAN_VAULT_PATH:-/home/ubuntu/Sites/projects/gp/obsidian-vault/Ved}"

if [ ! -d "$VAULT_PATH" ]; then
  echo "Error: Vault directory not found. Set OBSIDIAN_VAULT_PATH env var or create directory at /home/ubuntu/Sites/projects/gp/obsidian-vault/Ved"
  # STOP execution here — do not proceed
fi
```

If the vault directory is not found, output the error above and STOP. Do not attempt to create the note.

- Target folder: `content/yt-content/`

## BLOCKING REQUIREMENT — Vault Conventions

Before creating any note, load vault conventions by reading the `obsidian-vault-guide` skill. It is located at the same directory level as this skill:

```
Read: <skills-root>/obsidian-vault-guide/SKILL.md
```

Where `<skills-root>` is the parent directory of this skill's directory. For example, if this skill is at `skills/obsidian-note/SKILL.md`, read `skills/obsidian-vault-guide/SKILL.md`.

Do NOT read any hardcoded machine-specific paths such as `~/.openclaw/` or any path outside the project repository. The vault guide is always co-located with this skill inside the skills directory.

## Task Execution

### Step 1 — Validate input file

Check that the file path provided in `$ARGUMENTS` exists before reading it:
```bash
INPUT_FILE="$ARGUMENTS"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: Input file not found: $INPUT_FILE"
  # STOP execution here
fi
```

If the file does not exist, output the error above and STOP.

### Step 2 — Read the summary

Read the file at the path provided in `$ARGUMENTS`.

### Step 3 — Extract metadata

Extract from summary frontmatter: title, channel, URL, themes, duration.

### Step 4 — Determine output file path

- File name: `<YYYY-MM-DD>-<slug>.md` (slug from title: lowercase, spaces replaced with hyphens, special characters removed)
- Full path: `$VAULT_PATH/content/yt-content/<filename>`

### Step 5 — Check for existing file (overwrite guard)

Before writing, check if the output file already exists:
```bash
OUTPUT_FILE="$VAULT_PATH/content/yt-content/<filename>"

if [ -f "$OUTPUT_FILE" ]; then
  echo "Warning: A note already exists at $OUTPUT_FILE"
  echo "Overwrite? (yes/no)"
  # Wait for user confirmation before proceeding
  # If user says no → STOP
fi
```

If the file exists, warn the user and ask for confirmation. Do not overwrite without explicit confirmation.

### Step 6 — Generate Obsidian note

Create the note using these conventions (loaded from obsidian-vault-guide):

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
- See also: [[YouTube Content MOC]]

## Raw Notes
[Any additional details worth preserving]
```

### Step 7 — Save to vault

- Create the directory `$VAULT_PATH/content/yt-content/` if it doesn't exist.
- Write the generated note to `$VAULT_PATH/content/yt-content/<filename>`.

### Step 8 — Update YouTube Content MOC

Check for the MOC file at `$VAULT_PATH/content/yt-content/YouTube-Content-MOC.md`:

**If the MOC file exists:**
- Read the existing file.
- Append a wikilink entry for the new note under the `## Recent` section using this format:
  ```
  - [[<filename-without-extension>]] — <brief one-line description>
  ```
- Write the updated content back to the MOC file.

**If the MOC file does not exist:**
- Create it with the following structure, inserting the new note as the first entry:

```markdown
---
title: YouTube Content MOC
tags: [moc, youtube, content]
type: moc
---

# YouTube Content MOC

## Recent
- [[<filename-without-extension>]] — <brief one-line description>

## By Topic
<!-- Add topic sections as the collection grows -->
```

### Step 9 — Report results

```
Note created: <title>
Saved to: <vault-path>/content/yt-content/<filename>
Wikilinks: <N> created
MOC updated: YouTube-Content-MOC.md

Next: Open Obsidian to review, or run `/content-ideas <path>/summary.md`
```

## Obsidian Rules (from obsidian-vault-guide)

- ALWAYS use `[[Wikilink]]` syntax for internal references
- Use `> [!callout-type]` for callouts (tip, info, quote, warning)
- Include YAML frontmatter with tags, type, related
- Dense linking: every concept that could be its own note gets a wikilink
- If a referenced note doesn't exist, link it anyway (Obsidian handles forward references)
- Every note MUST link to at least 2 other notes
- Tag notes for discoverability (#youtube, #content, #topic-name)
