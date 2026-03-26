# contextsync Setup Guide

## Purpose

This file is loaded when running the `contextsync setup` task. Follow the procedure
below exactly. Do not skip steps. Do not run setup if CLAUDE.md does not exist at the
project root — halt and inform the user.

---

## 1. When to Run Setup

Run setup in these situations:
- First time adopting contextsync on a project (no `## Context Navigation` in CLAUDE.md yet)
- After adding a new app to a monorepo (new app needs its own docs scaffold)
- After `## Context Navigation` was manually removed from CLAUDE.md
- When some `docs/` structure exists but stubs are missing (setup fills gaps and writes bridge)

Setup is re-runnable and safe. When `## Context Navigation` is already present, setup
detects it, skips re-writing CLAUDE.md, and only creates any missing stubs.

---

## 2. Domain Naming Guidance

Domains are the top-level subfolders inside `docs/`. Name them to match the questions
developers ask, not the source tree structure.

**Recommended names by project type:**

| Project type | Suggested domains |
|---|---|
| Backend service / API | `features`, `engineering`, `infrastructure` |
| Frontend app | `features`, `components`, `pages` |
| Full-stack monolith | `features`, `engineering`, `infrastructure`, `agents` |
| Data / ML platform | `pipelines`, `models`, `infrastructure` |
| Library / SDK | `api`, `guides`, `examples` |

**Rule**: A domain name should complete this sentence — "I'm looking for docs about ___."
If "I'm looking for docs about src" sounds wrong, the name is too technical. Use `engineering`
or `backend` instead.

**Minimum**: One domain (`features/`) is valid. Start small; add domains as documentation grows.

---

## 3. Monorepo Walkthrough

### Branch A — docs/ does not exist (new project)

**Setup scenario**: Monorepo with two apps — `apps/web` (React frontend) and `apps/api`
(Node.js backend). CLAUDE.md exists at the project root with no `## Context Navigation`.

**Step 2 — monorepo question:**
> Is this a monorepo with multiple apps? (yes/no)

User answers: `yes`

> List your apps as name:path pairs, one per line. Path is the app root (no trailing slash).
> Enter a blank line when done.

User enters:
```
web:apps/web
api:apps/api

```
(blank line to finish)

**Trailing slash normalization**: If a user enters `web:apps/web/` (with trailing slash),
it is normalized to `web:apps/web` before storing. Same for leading slashes:
`/apps/web/` → `apps/web`.

Skill stores:
- `web` → app root `apps/web` → DOCS_ROOT `apps/web/docs`
- `api` → app root `apps/api` → DOCS_ROOT `apps/api/docs`

**Step 3 — domain check for each app:**

`apps/web/docs/` does not exist →
> What domains do you want for "web"? (e.g. features, components, pages)

User answers: `features, components`

`apps/api/docs/` does not exist →
> What domains do you want for "api"? (e.g. features, engineering, infrastructure)

User answers: `features, engineering, infrastructure`

**Step 4 — stubs created:**
```
apps/web/docs/CONTEXT.md              ← Layer 1 stub (created)
apps/web/docs/features/CONTEXT.md     ← Layer 2 stub (created)
apps/web/docs/components/CONTEXT.md   ← Layer 2 stub (created)
apps/api/docs/CONTEXT.md              ← Layer 1 stub (created)
apps/api/docs/features/CONTEXT.md     ← Layer 2 stub (created)
apps/api/docs/engineering/CONTEXT.md  ← Layer 2 stub (created)
apps/api/docs/infrastructure/CONTEXT.md ← Layer 2 stub (created)
```

**Step 5 — CLAUDE.md written:**
```markdown
## Context Navigation
web: apps/web/docs/CONTEXT.md
api: apps/api/docs/CONTEXT.md
```

### Branch B — docs/ exists with subfolders (re-run or partial setup)

**Setup scenario**: Same monorepo, but `apps/web/docs/` already exists with subfolders
`features/` and `components/`. A developer runs setup again after adding the `apps/api` app.

**Step 3 — domain check for web:**

`apps/web/docs/` exists and has subfolders `features/`, `components/` →
> Found these domains for "web": features, components. Add or remove any? (enter to confirm)

User presses Enter to confirm.

**Step 3 — domain check for api:**

`apps/api/docs/` does not exist →
> What domains do you want for "api"? (e.g. features, engineering, infrastructure)

User answers: `features, engineering, infrastructure`

(Steps 4 and 5 proceed as in Branch A for the new `api` app. Existing `web` stubs are
skipped — setup never overwrites them.)

---

## 4. Partial Structure Handling

Setup is re-runnable. It fills in whatever is missing and never overwrites what exists.

**Scenario**: `## Context Navigation` is already in CLAUDE.md (from a previous setup run)
but `apps/api/docs/infrastructure/CONTEXT.md` was never created.

Setup detects the existing `## Context Navigation`, reads the entry points from it,
skips Step 2 (no questions asked about app names/paths), proceeds to Step 3 to check
each DOCS_ROOT for missing stubs, creates only the missing stub, skips Step 5
(no CLAUDE.md re-write needed), then reports:

```
Created:  apps/api/docs/infrastructure/CONTEXT.md
Skipped:  apps/web/docs/CONTEXT.md (already exists)
Skipped:  apps/web/docs/features/CONTEXT.md (already exists)
... (all other existing files)
CLAUDE.md: no changes (## Context Navigation already present)
```

**Rule**: If `## Context Navigation` exists but you need to add a NEW app to the monorepo,
manually add a new labeled line to `## Context Navigation` first, then re-run setup.
Setup will detect the new entry, scaffold its docs/, and skip everything that already exists.

---

## 5. Verifying the Setup

After setup completes, verify the bridge is working correctly:

1. **Check CLAUDE.md** — confirm `## Context Navigation` is present with the correct path(s).
2. **Check entry point exists** — read the path listed under `## Context Navigation`
   (e.g., `docs/CONTEXT.md`). Confirm the file exists and is a valid CONTEXT.md stub.
3. **Check Layer 2 stubs** — read `docs/{domain}/CONTEXT.md` for each domain.
   Confirm each file exists and has the 3 mandatory sections (Purpose, Files, When to Use).
4. **Run navigation test** — give the skill a simple task (e.g., "What features are documented?").
   Confirm it reads CLAUDE.md → finds `## Context Navigation` → reads `docs/CONTEXT.md` →
   routes to the correct domain CONTEXT.md without asking for clarification.

If any verification step fails:
- Missing file → re-run `contextsync setup` (it will create the missing stubs).
- Wrong path in CLAUDE.md → edit `## Context Navigation` manually, then re-run setup.
- Stub has wrong sections → edit the stub using the template in `references/context-md-spec.md`.
