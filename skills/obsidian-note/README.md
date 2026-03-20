# obsidian-note skill

Creates a fully formatted Obsidian vault note from a content summary file and saves it to your vault. Handles frontmatter, wikilinks, callouts, and automatically updates the YouTube Content MOC.

## What it does

1. Reads a content summary markdown file you provide.
2. Extracts metadata (title, channel, URL, themes, duration).
3. Generates a structured Obsidian note with frontmatter, callouts, wikilinks, and sections.
4. Saves the note to `<vault>/content/yt-content/<YYYY-MM-DD>-<slug>.md`.
5. Creates or updates `<vault>/content/yt-content/YouTube-Content-MOC.md` with a wikilink to the new note.

## Prerequisites

- An Obsidian vault must exist on disk.
- By default the skill looks for the vault at `/home/ubuntu/Sites/projects/gp/obsidian-vault/Ved`. Set the `OBSIDIAN_VAULT_PATH` environment variable if your vault is elsewhere (see below).
- The `obsidian-vault-guide` skill must be present alongside this skill (`skills/obsidian-vault-guide/SKILL.md`) — it is loaded automatically and provides vault conventions.

## Usage

```
/obsidian-note path/to/summary.md
```

### Example

```
/obsidian-note ~/Downloads/yt-summary-react-server-components.md
```

The skill will:
- Read `~/Downloads/yt-summary-react-server-components.md`
- Generate a note such as `2026-03-20-react-server-components.md`
- Save it to `<vault>/content/yt-content/2026-03-20-react-server-components.md`
- Append an entry to `<vault>/content/yt-content/YouTube-Content-MOC.md`

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `OBSIDIAN_VAULT_PATH` | No | Absolute path to the root of your Obsidian vault (the `Ved/` folder). Falls back to `/home/ubuntu/Sites/projects/gp/obsidian-vault/Ved` if not set. |

Set it in your shell profile or inline:

```bash
export OBSIDIAN_VAULT_PATH=/path/to/your/vault/Ved
```

## What gets created

### Note file

Saved to: `$OBSIDIAN_VAULT_PATH/content/yt-content/<YYYY-MM-DD>-<slug>.md`

Contains:
- YAML frontmatter (title, channel, url, date_created, tags, type, related)
- Source info callout
- Summary section
- Key Insights section (Obsidian tip callouts)
- Topics Covered (with wikilinks)
- Notable Quotes (Obsidian quote callouts)
- Connections section
- Raw Notes section

### MOC update

File: `$OBSIDIAN_VAULT_PATH/content/yt-content/YouTube-Content-MOC.md`

- If the MOC already exists, a wikilink to the new note is appended under `## Recent`.
- If the MOC does not exist, it is created with the new note as the first entry.

## Error handling

- If the vault directory does not exist, the skill stops with: `Error: Vault directory not found. Set OBSIDIAN_VAULT_PATH env var or create directory at /home/ubuntu/Sites/projects/gp/obsidian-vault/Ved`
- If the input summary file does not exist, the skill stops with: `Error: Input file not found: <path>`
- If a note with the same filename already exists, the skill warns you and asks for confirmation before overwriting.
