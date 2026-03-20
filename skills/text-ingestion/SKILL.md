---
name: text-ingestion
description: "Normalise a written notes or blog draft file (.md or .txt) into the standard source.md format so the rest of the content pipeline works unchanged."
argument-hint: 'text-ingestion path/to/notes-or-draft.md'
allowed-tools: Read, Write
---

# Text Ingestion

Normalise a written input file into the same `source.md` format produced by `yt-transcript`, so the rest of the pipeline (`content-summarizer`, `blog-generator`, etc.) works without modification.

## Execution Logic

Check `$ARGUMENTS`:
- If **empty** → respond: "Text Ingestion loaded. Usage: `/text-ingestion <path-to-file.md|.txt>`" and STOP.
- If **has arguments** → treat as file path and execute below.

## Task Execution

### 1. Read the input file

Read the file at the path provided in `$ARGUMENTS`. Accept `.md` and `.txt` files.

If the file does not exist or cannot be read → respond:
```
Error: Cannot read file at <path>. Check the path and try again.
```
and STOP.

### 2. Detect input type

Classify the file as one of two types:

**`notes`** — raw, unpolished material. Indicators:
- Bullet lists without prose paragraphs
- Short fragments or incomplete sentences
- Inline tags, TODOs, question marks
- No clear intro/conclusion structure
- Typically under 400 words

**`draft`** — polished or near-polished prose. Indicators:
- Full sentences and paragraphs
- Logical flow with intro + body + conclusion
- Heading structure (H1 → H2 → H3)
- Typically over 400 words with coherent narrative

### 3. Extract metadata

- **title** — Use the first H1 (`# Title`) if present; otherwise use the first non-blank line. If neither is suitable, infer a short descriptive title from the content.
- **wordCount** — Count all words in the file body (excluding frontmatter if present).
- **readTime** — `ceil(wordCount / 200)` minutes (average reading speed).
- **topics** — Extract from all H2 headings (`## Heading`). If no H2 headings exist, infer 2-4 main topics from recurring terms or prominent ideas in the text. Output as a YAML list.
- **slug** — Lowercase the title, replace spaces and special characters with hyphens, strip punctuation. Max 50 chars.
- **date** — Today's date in `YYYY-MM-DD` format.

### 4. Determine output path

```
$OBSIDIAN_VAULT_PATH/content/<YYYY-MM-DD>-<slug>/source.md
```

Read `OBSIDIAN_VAULT_PATH` from the `~/.config/content-pipeline/.env` file (or shell env). Default: `~/obsidian`.

Create the folder if it does not exist.

### 5. Write source.md

Write the file with this exact structure:

```markdown
---
title: [detected or inferred title]
type: written
source: [original absolute file path]
date: [YYYY-MM-DD]
wordCount: [N]
readTime: [N min]
topics:
  - [topic 1]
  - [topic 2]
  - [topic 3]
inputType: [notes|draft]
---

[Full original content — reproduced exactly as-is below the frontmatter]
```

Do not modify, reformat, or summarise the body content. Reproduce it verbatim.

### 6. Report results

```
✅ Text ingestion complete
📁 Source: <original-path>
📁 Output: <output-path>/source.md
📊 Words: <N> | Read time: <N> min | Type: <notes|draft>
🏷️  Topics detected: <topic 1>, <topic 2>, ...

Next: Run `/content-summarizer <output-path>/source.md`
```

## Quality Rules

- Never alter the original content — the body below the frontmatter must be verbatim
- If the file already has YAML frontmatter, strip it before reproducing the body (the new frontmatter replaces it)
- `inputType: notes` signals to downstream skills that the content may need more structuring; `inputType: draft` signals it is closer to publishable
- Topics list must reflect actual content — do not invent generic labels like "Introduction" or "Conclusion"
- If the title is ambiguous, err toward specificity: infer from subject matter, not file name
