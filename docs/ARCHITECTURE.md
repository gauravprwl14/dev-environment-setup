# Architecture — Claude Code Skills-Based Content Pipeline

This document is reference documentation for developers who want to understand or extend the content pipeline. It covers the plugin/skill model, how installation works, dependency management, and the full data flow.

---

## 1. Plugin vs Skill

### The analogy

Think of the relationship like npm packages and exported functions:

- A **skill** is like an exported function — it is the atomic unit of capability.
- A **plugin** is like an npm package — it bundles one or more skills into an installable unit.

### How each is defined

A **skill** is defined by a `SKILL.md` file with YAML frontmatter:

```yaml
---
name: yt-transcript
description: "Extract YouTube transcript..."
argument-hint: 'yt-transcript <url>'
allowed-tools: Bash, Read, Write
---
```

Claude reads the `SKILL.md` and follows its instructions when the user types `/yt-transcript`. Each skill is a self-contained capability.

A **plugin** is defined by a `.claude-plugin/plugin.json` file that groups one or more skills into an installable package:

```json
{ "name": "content-pipeline", "skills": ["./yt-transcript", "./content-summarizer", ...] }
```

The `npx skills install` CLI reads `plugin.json` to know what skills to install. Each skill also has its own `.claude-plugin/plugin.json` for individual installs when you only want one skill.

### Comparison table

| | Skill | Plugin |
|---|---|---|
| Defined by | `SKILL.md` with YAML frontmatter | `.claude-plugin/plugin.json` |
| Unit | Single capability | Bundle of skills |
| Analogy | Exported function | npm package |
| Invoked by | `/skill-name` slash command | `npx skills install` |
| Install granularity | One skill at a time | All skills in the bundle |

---

## 2. Skill Types

There are two skill types in this pipeline.

### LLM-native

Claude executes the `SKILL.md` instructions directly. There are no scripts, no external processes, and no dependencies. Claude uses its built-in language and reasoning capabilities to produce the output.

**Pros**: Zero setup, no runtime dependencies, works anywhere Claude Code runs.
**Cons**: Limited to what Claude can do without external tools — cannot make API calls, call external services, or run arbitrary code reliably.

**Examples from this pipeline**: `content-summarizer`, `content-ideas`, `blog-generator`, `social-posts`, `tweet-generator`, `carousel-generator`, `instagram-caption`, `obsidian-note`, `gemini-prompt-generator`, `youtube-pipeline` (orchestrator).

### Script-backed

Has a `scripts/` directory. Claude shells out to a Python or Node.js script to perform the actual work. The `SKILL.md` instructs Claude to run the script and handle its output.

**Pros**: Can call APIs, access the file system, use third-party libraries, and do things Claude cannot do natively.
**Cons**: Requires a runtime (Python or Node.js) and any dependencies to be installed in the environment.

**Examples from this pipeline**: `yt-transcript` (Python), `image-generator` (Python), `hashnode` (Node.js).

---

## 3. How Installation Works

The `npx skills` CLI handles installation:

```bash
npx skills install <path-or-npm-package> --yes
```

**What happens during install:**

1. The CLI reads `plugin.json` from the specified path or npm package.
2. For each skill listed under `"skills"`, it copies the skill directory into `.agents/skills/<name>/` in the target project.
3. Claude Code scans `.agents/skills/` at startup and discovers available slash commands from the `SKILL.md` files found there.

**Local install** (used in this repo):
```bash
npx skills install ./skills --yes
```

**Production / marketplace install** (skills published to npm):
```bash
npx skills install author/skill-name
```

After installation, users can invoke any installed skill with its slash command, e.g. `/yt-transcript`, `/content-summarizer`, `/youtube-pipeline`.

---

## 4. Dependency Shipping in Production

Script-backed skills have external dependencies. There are three standard approaches used in production:

### Approach 1 — Bundle with esbuild/webpack (most common for Node.js)

Bundle everything into a single `dist/bundle.js` with zero runtime npm dependencies. The user never needs to run `npm install`.

```bash
esbuild scripts/hashnode-client.js --bundle --outfile=dist/bundle.js
```

Best when: You control the Node.js scripts and want the smoothest installation experience.

### Approach 2 — Declare as plugin dependencies in plugin.json

The installer reads a `dependencies` field in `plugin.json` and runs `npm install` automatically during skill installation.

Best when: Bundling is not feasible or the dependency list is small and stable.

### Approach 3 — Python requirements.txt

Ship a `requirements.txt` alongside the Python scripts and document `pip install -r requirements.txt` in the skill's setup instructions. For fully standalone distribution, PyInstaller can produce a single binary.

Best when: The skill is Python-based and the user base is comfortable with Python tooling.

### Technical debt — hashnode scripts

The `hashnode` skill's scripts are **not bundled**. They have a `package.json` with external dependencies (graphql, etc.), meaning users must manually run `npm install` inside the skill directory before the skill works. This is a known technical debt item. The correct production fix is to run:

```bash
esbuild scripts/hashnode-client.js --bundle --outfile=dist/bundle.js
```

and ship the bundle instead of the raw scripts.

---

## 5. Pipeline Architecture

### Data flow

```
YouTube URL
    │
    ▼
[yt-transcript]          ← Python script, youtube-transcript-api/yt-dlp
    │                       Output: transcript.md
    ▼
[content-summarizer]     ← LLM reads transcript, writes structured summary
    │                       Output: summary.md
    ├──────────────────────────────────────────────────────────┐
    ▼                                                          ▼
[obsidian-note]          ← LLM writes vault note         [hashnode]  ← Node.js script
    │   Output: Obsidian vault/<date>-<slug>.md               │   Output: Hashnode draft
    ▼
[content-ideas]          ← LLM generates 5 ideas
    │                       Output: ideas.md
    ├───────────────────────────────────────────────────────────────────┐
    │                                                                   │
    ▼                                                                   ▼
[gemini-prompt-generator]  ← LLM, 3 variants per idea      [social-posts]    LLM
    │   Output: prompts.md   (Cinematic/Illustrative/Minimal)  Output: social-posts.md
    ▼
[image-generator]        ← Python, Gemini API              [tweet-generator]  LLM
    │   Output: images/                                        Output: tweets.md

                                                           [blog-generator]   LLM
                                                               Output: blog.md

                                                           [carousel-generator] LLM
                                                               Output: carousel.md

                                                           [instagram-caption]  LLM
                                                               Output: captions.md
```

### The orchestrator pattern

The `youtube-pipeline` skill is an **orchestrator** — it is LLM-native but its sole job is to invoke the other skills in the correct sequence. It does not produce content itself. Between each step it presents a confirmation gate, allowing the user to review the output of one step before proceeding to the next.

This pattern means:
- Each individual skill can be tested and used independently.
- The orchestrator provides the end-to-end "one command does everything" experience without duplicating logic.
- Failures are isolated — a bad transcript does not silently produce bad downstream content.

---

## 6. Skill Inventory

| Skill | Type | Script language | What it does |
|---|---|---|---|
| `yt-transcript` | Script-backed | Python | Extracts YouTube transcript via youtube-transcript-api/yt-dlp |
| `content-summarizer` | LLM-native | — | Structures transcript into summary.md |
| `obsidian-note` | LLM-native | — | Creates Obsidian vault note from summary |
| `content-ideas` | LLM-native | — | Generates 5 content ideas from summary |
| `gemini-prompt-generator` | LLM-native | — | Generates 3 Gemini image prompt variants per idea |
| `image-generator` | Script-backed | Python | Calls Gemini API to generate images |
| `social-posts` | LLM-native | — | Writes LinkedIn/Twitter/IG posts from ideas |
| `tweet-generator` | LLM-native | — | Writes tweet threads from ideas |
| `blog-generator` | LLM-native | — | Writes long-form blog post |
| `carousel-generator` | LLM-native | — | Creates LinkedIn carousel slides |
| `instagram-caption` | LLM-native | — | Writes Instagram captions |
| `hashnode` | Script-backed | Node.js | Publishes blog draft to Hashnode via GraphQL |
| `youtube-pipeline` | LLM-native (orchestrator) | — | Runs the full pipeline end-to-end |
| `text-ingestion` | LLM-native | — | Ingests written notes/drafts into pipeline |
| `obsidian-vault-guide` | LLM-native (reference) | — | Background knowledge for obsidian-note |
| `content-pipeline` | LLM-native | — | Alias/guide for the pipeline |
| `skill-scaffold` | LLM-native | — | Generates new skill boilerplate |

---

## 7. File System Layout

### Installed skills

After `npx skills install ./skills --yes`, skills land here in the target project:

```
.agents/
└── skills/
    ├── yt-transcript/
    ├── content-summarizer/
    ├── obsidian-note/
    ├── content-ideas/
    ├── gemini-prompt-generator/
    ├── image-generator/
    ├── social-posts/
    ├── tweet-generator/
    ├── blog-generator/
    ├── carousel-generator/
    ├── instagram-caption/
    ├── hashnode/
    ├── youtube-pipeline/
    └── ...
```

Claude Code scans `.agents/skills/` at startup to discover available slash commands.

### Pipeline output

All pipeline outputs go to `$CONTENT_PIPELINE_OUTPUT/<date>-<video-slug>/`:

```
$CONTENT_PIPELINE_OUTPUT/
└── 2026-03-20-how-ai-is-changing-everything/
    ├── transcript.md
    ├── summary.md
    ├── ideas.md
    ├── prompts.md
    ├── images/
    │   ├── idea-1-cinematic.png
    │   ├── idea-1-illustrative.png
    │   └── ...
    ├── social-posts.md
    ├── tweets.md
    └── blog.md
```

Obsidian notes are written separately to `$OBSIDIAN_VAULT_PATH/content/yt-content/` and are not part of the main output directory.
