# contextsync Docs-Only Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the contextsync skill so all CONTEXT.md files live exclusively in `docs/`, add an explicit `## Context Navigation` bridge in CLAUDE.md, and introduce a `contextsync setup` command that auto-generates the bridge and scaffolds the docs structure.

**Architecture:** Four skill files change — SKILL.md gains a bootstrap step and two decision tree branches; 3-layer-system.md and context-md-spec.md update their templates to reflect docs-only placement; a new setup-guide.md provides the interactive setup procedure. No code — all changes are to markdown files in `skills/contextsync/`.

**Spec:** `docs/superpowers/specs/2026-03-26-contextsync-docs-only-design.md`

**Tech Stack:** Markdown, Claude Code skill conventions (YAML frontmatter, relative file references)

---

## File Map

| Action | Path | What changes |
|---|---|---|
| Modify | `skills/contextsync/SKILL.md` lines 21–90 | Add bootstrap block to Navigation Protocol (lines 21–43, including exception handling table); add 2 branches to Task Decision Tree (lines 45–70); fix `/CONTEXT.md` reference in Quality Gates note (line 90); add setup-guide.md to Reference Files table |
| Modify | `skills/contextsync/references/3-layer-system.md` — five targeted replacements + append at end | Five changes: (1) Layer 1 definition block, (2) Layer 2 tree, (3) reference directory tree + callout, (4) navigation scenario including `**Never**` line, (5) append Layer 3 naming note + scaling pattern + Advanced note after last edge case section |
| Modify | `skills/contextsync/references/context-md-spec.md` lines 68–92 | Update Root CONTEXT.md template heading and purpose text; preserve trailing `---` separator |
| Create | `skills/contextsync/references/setup-guide.md` | New file — 5 sections: when to run, domain naming, monorepo walkthrough (both branches: new and existing docs/), partial structure handling, verifying setup |

---

## Task 1: Update SKILL.md — Navigation Protocol Bootstrap

**Files:**
- Modify: `skills/contextsync/SKILL.md` lines 21–43

The Navigation Protocol currently goes straight to the 3-layer chain. Add a mandatory bootstrap block before the chain that reads `## Context Navigation` from CLAUDE.md and selects the entry point. The exception handling table (lines 34–43) is preserved inside the new Step 1 section.

- [ ] **Step 1: Verify the acceptance criteria this task must satisfy**

  Check that after this edit, SKILL.md contains:
  - A "Bootstrap" section before the 3-layer chain diagram
  - Halt + warn behavior when `## Context Navigation` is absent
  - Single-entry path (use directly)
  - Multi-entry path (derive app root, match, ask if ambiguous)
  - Exception handling table preserved under Step 1

- [ ] **Step 2: Replace the Navigation Protocol section (lines 21–43)**

  The target section spans lines 21–43 of `skills/contextsync/SKILL.md`. It starts at
  the `## Navigation Protocol — MANDATORY, always run first` heading and ends at the `---`
  separator on line 43. The section contains the chain diagram (inside a code fence) and
  the exception handling table. Match using the unique opening heading:
  `## Navigation Protocol — MANDATORY, always run first`

  Replace the entire section (lines 21–43, exclusive of the `---` separator) with:

  ````markdown
  ## Navigation Protocol — MANDATORY, always run first

  ### Step 0: Bootstrap — find the entry point

  Read CLAUDE.md and find the `## Context Navigation` section before doing anything else.

  ```
  ## Context Navigation present?
  │
  ├─ NO (section absent) AND task is not "setup"
  │    → Warn: "No '## Context Navigation' found in CLAUDE.md. Run contextsync setup."
  │    → HALT. Do not proceed.
  │
  ├─ Single entry — one path, no label (e.g. "docs/CONTEXT.md")
  │    → Use that path as the Layer 1 entry point.
  │
  └─ Multiple labeled entries (e.g. "web: apps/web/docs/CONTEXT.md")
       → Derive app root per entry: strip "/docs/CONTEXT.md" suffix.
         Example: "apps/web/docs/CONTEXT.md" → app root "apps/web"
       → Match task context against app roots and label names:
           a. File paths in task start with an app root → use that entry point.
           b. App label name mentioned in task → use that entry point.
           c. No clear signal → ask once: "Which app? [label1 | label2 | ...]"
              (show actual label names from ## Context Navigation)
  ```

  ### Step 1: Follow the 3-layer chain

  **Never skip a level. Never read a content file without first reading its parent CONTEXT.md.**

  ```
  {entry point}                              ← Layer 1: domain router (from ## Context Navigation)
    └── {entry-point-dir}/{domain}/CONTEXT.md ← Layer 2: domain router
          └── {subdomain}/CONTEXT.md          ← Layer 2: file router (if needed)
                └── target file               ← Layer 3: content
  ```

  **Exception handling:**

  | Situation | Action |
  |---|---|
  | CONTEXT.md missing at any level | Create stub (see `references/context-md-spec.md`), log as debt, continue |
  | Routing entry → nonexistent file | Mark STALE in Documentation Plan, remove it in current task |
  | Circular reference detected | Flag as blocker, do not follow the loop |
  | CONTEXT.md > 100 lines | Split immediately before any other work |
  ````

- [ ] **Step 3: Verify the edit**

  Read `skills/contextsync/SKILL.md` lines 21–60 and confirm:
  - Bootstrap block (Step 0) is present before the chain diagram
  - Halt path is explicit for absent `## Context Navigation`
  - App root derivation rule is present ("strip /docs/CONTEXT.md suffix")
  - Single-entry and multi-entry paths both covered
  - Exception handling table still present under Step 1

- [ ] **Step 4: Commit**

  ```bash
  cd /Users/gauravporwal/Sites/projects/gp/dev-environment-setup
  git add skills/contextsync/SKILL.md
  git commit -m "feat(contextsync): add bootstrap step to navigation protocol"
  ```

---

## Task 2: Update SKILL.md — Task Decision Tree + Reference Files Table + Quality Gates Note

**Files:**
- Modify: `skills/contextsync/SKILL.md` — Task Decision Tree section (lines 45–72), Quality Gates note (line 90), Reference Files table (lines 140–148)

- [ ] **Step 1: Verify acceptance criteria**

  After this edit, SKILL.md must contain:
  - A "setup" branch at the top of the decision tree
  - A "## Context Navigation missing" branch at the top of the decision tree
  - `references/setup-guide.md` in the Reference Files table with its load condition
  - Quality Gates note references `docs/CONTEXT.md` (not `/CONTEXT.md`)

- [ ] **Step 2: Replace the Task Decision Tree section (lines 45–70 only — do NOT include the closing `---`)**

  The `---` on line 72 separates the Decision Tree from Quality Gates and must be preserved.
  Match using the unique section heading `## Task Decision Tree` and replace ONLY the heading
  + code block (lines 45–70), stopping before the `---` on line 72.

  Replace (lines 45–70, the heading and code block, no trailing `---`):

  > `## Task Decision Tree` (line 45) through the closing ` ``` ` (line 70)

  With this replacement (no trailing `---` — the separator is already in the file):

  ````markdown
  ## Task Decision Tree

  ```
  Incoming task
  │
  ├─ "setup" / "initialize docs" / "contextsync setup"
  │    └─ LOAD references/setup-guide.md → RUN setup procedure
  │
  ├─ ## Context Navigation missing from CLAUDE.md AND task is not "setup"
  │    └─ WARN: "No '## Context Navigation' found in CLAUDE.md. Run contextsync setup."
  │         → HALT. Do not proceed.
  │
  ├─ new feature / new endpoint / new module
  │    └─ CREATE feature guide + UPDATE parent CONTEXT.md routing
  │
  ├─ modify feature / change service / refactor module
  │    └─ UPDATE existing feature guide + VERIFY CONTEXT.md chain still resolves
  │
  ├─ new error code / modify error
  │    └─ UPDATE error source + UPDATE Error Cases table in feature guide
  │
  ├─ new config key / new env var
  │    └─ UPDATE feature guide Configuration section
  │
  ├─ audit / "stale docs" / "routing broken"
  │    └─ RUN cross-reference verification → output stale entry report
  │
  ├─ doc review / PR review
  │    └─ CHECK required sections present + CONTEXT.md size gate + cross-reference integrity
  │
  └─ agent handoff received
       └─ PARSE handoff schema (see references/agent-handoffs.md) → map to above tasks
  ```
  ````

- [ ] **Step 3: Update Hard Stop #1 to exempt `contextsync setup` writes to CLAUDE.md**

  Hard Stop #1 (line 171 of SKILL.md) currently prohibits ALL CLAUDE.md modification.
  `contextsync setup` must write `## Context Navigation` into CLAUDE.md, which would
  violate this Hard Stop as written. Narrow the rule to permit this one exemption.

  In the Hard Stops section, replace:

  ```
  1. **Modifying CLAUDE.md** — Layer 1 is read-only. Changes require explicit human approval.
  ```

  With:

  ```
  1. **Modifying CLAUDE.md** — Layer 1 is read-only. The only permitted write is the
     `## Context Navigation` block added by `contextsync setup`. All other changes require
     explicit human approval.
  ```

- [ ] **Step 4: Fix the Quality Gates note (line 90)**

  In the Quality Gates section, replace:

  ```
  > **Project configuration required**: G3 and G4 source paths are project-specific.
  > Before running any task, confirm the error source location and config source location
  > for this project from CLAUDE.md or `/CONTEXT.md`. Never assume paths.
  ```

  With:

  ```
  > **Project configuration required**: G3 and G4 source paths are project-specific.
  > Before running any task, confirm the error source location and config source location
  > for this project from CLAUDE.md or `docs/CONTEXT.md`. Never assume paths.
  ```

- [ ] **Step 5: Add setup-guide.md row to Reference Files table**

  In the Reference Files table, add a new row after the `references/context-md-spec.md` row:

  ```
  | `references/setup-guide.md` | Running `contextsync setup` — contains the full interactive setup procedure, domain naming guidance, and monorepo walkthrough |
  ```

- [ ] **Step 6: Verify**

  Read `skills/contextsync/SKILL.md` decision tree, Quality Gates note, Hard Stops, and reference table. Confirm:
  - "setup" branch is the first branch in the tree
  - "## Context Navigation missing" is the second branch
  - Quality Gates note references `docs/CONTEXT.md` not `/CONTEXT.md`
  - Hard Stop #1 permits `## Context Navigation` writes by setup
  - `references/setup-guide.md` row is present in the reference table

- [ ] **Step 7: Commit**

  ```bash
  git add skills/contextsync/SKILL.md
  git commit -m "feat(contextsync): add setup branch, context-navigation guard, fix docs path reference, and narrow hard stop #1"
  ```

---

## Task 3: Update references/3-layer-system.md

**Files:**
- Modify: `skills/contextsync/references/3-layer-system.md` (full file rewrite of layers 1–3 sections and directory tree)

Five changes: (1) Layer 1 definition → `docs/CONTEXT.md` is the entry point, not project-root `/CONTEXT.md`. (2) Layer 2 tree → remove the project-root `/CONTEXT.md` level. (3) Reference directory tree → docs-only structure. (4) Navigation scenario → uses `docs/CONTEXT.md` and preserves the `**Never**` line. (5) Add Layer 3 naming conventions + scaling pattern + Advanced note at end.

- [ ] **Step 1: Verify acceptance criteria**

  After this edit, 3-layer-system.md must:
  - Show `docs/CONTEXT.md` as the Layer 1 entry point (not `/CONTEXT.md`)
  - Reference directory tree must not have a root-level `CONTEXT.md`
  - Navigation scenario must start at `docs/CONTEXT.md`
  - Include Layer 3 naming conventions (FEAT- prefix for features/, plain names elsewhere)
  - Include the scaling sub-domain pattern
  - Include a brief "Advanced: source-mirror" note at the end

- [ ] **Step 2: Replace Layer 1 definition block (lines 13–24)**

  Replace:
  ```markdown
  ### Layer 1 — Root Configuration (READ ONLY)

  ```
  CLAUDE.md          ← Coding rules, mandatory patterns, conventions
                        NEVER modify directly. Changes require human approval.

  /CONTEXT.md        ← Project-level router. Maps developer questions to the
                        correct docs/ subfolder. Under 100 lines always.
  ```

  **Rule**: CLAUDE.md is infrastructure config. Treat it like production environment variables —
  you can read it, you can reference it, you cannot edit it without explicit sign-off.
  ```

  With:
  ```markdown
  ### Layer 1 — Entry Point (READ ONLY)

  ```
  CLAUDE.md              ← Coding rules, conventions, ## Context Navigation bridge.
                            NEVER modify directly. Changes require human approval.

  docs/CONTEXT.md        ← Layer 1: domain router. The entry point declared in
                            CLAUDE.md's ## Context Navigation section. ≤ 100 lines.
  ```

  **Rule**: CLAUDE.md is infrastructure config — read it, reference it, never edit it without
  explicit sign-off. The `## Context Navigation` section in CLAUDE.md tells the agent which
  `docs/CONTEXT.md` path to use as the Layer 1 entry point.
  ```

- [ ] **Step 3: Replace Layer 2 tree (lines 28–46)**

  Replace this full block:
  ```markdown
  ### Layer 2 — Routing Tables

  ```
  /CONTEXT.md
    └── docs/CONTEXT.md                        ← maps topics → docs subfolder
          ├── docs/features/CONTEXT.md          ← maps questions → feature guides
          ├── docs/engineering/CONTEXT.md       ← maps questions → engineering docs
          ├── docs/infrastructure/CONTEXT.md    ← maps questions → infra docs
          └── docs/agents/CONTEXT.md            ← maps agent types → agent folders
                ├── docs/agents/backend/CONTEXT.md
                ├── docs/agents/frontend/CONTEXT.md
                └── docs/agents/shared/CONTEXT.md
  ```
  ```

  With:
  ```markdown
  ### Layer 2 — Routing Tables

  ```
  docs/CONTEXT.md                             ← Layer 1: maps topics → domain subfolder
    ├── docs/features/CONTEXT.md              ← Layer 2: maps questions → feature guides
    ├── docs/engineering/CONTEXT.md           ← Layer 2: maps questions → engineering docs
    ├── docs/infrastructure/CONTEXT.md        ← Layer 2: maps questions → infra docs
    └── docs/agents/CONTEXT.md               ← Layer 2: maps agent types → agent folders
          ├── docs/agents/backend/CONTEXT.md
          ├── docs/agents/frontend/CONTEXT.md
          └── docs/agents/shared/CONTEXT.md
  ```

  **Rules for every CONTEXT.md:**
  - ≤ 100 lines, always
  - Contains ONLY: Purpose (2 sentences), Files table, When to Use bullets
  - No explanatory prose, no code examples, no diagrams
  - Every entry in Files table must point to a file that actually exists
  ```

- [ ] **Step 4: Replace Reference Directory Tree (lines 74–115)**

  Replace the full tree block and its callout with:

  ````markdown
  ## Reference Directory Tree (template — adapt to your project)

  ```
  project-root/
  ├── CLAUDE.md                               ← L1: rules + ## Context Navigation bridge
  │
  └── docs/
      ├── CONTEXT.md                          ← L1: domain router (entry point)
      │
      ├── features/
      │   ├── CONTEXT.md                      ← L2: feature router
      │   ├── FEAT-user-authentication.md     ← L3: feature guide
      │   ├── FEAT-order-fulfillment.md       ← L3: feature guide
      │   └── FEAT-payment-processing.md      ← L3: feature guide
      │
      ├── engineering/
      │   ├── CONTEXT.md                      ← L2: engineering router
      │   ├── architecture-overview.md        ← L3
      │   └── module-patterns.md              ← L3
      │
      ├── infrastructure/
      │   ├── CONTEXT.md                      ← L2: infra router
      │   └── deployment-config.md            ← L3
      │
      └── agents/
          ├── CONTEXT.md                      ← L2: agent type router
          ├── shared/
          │   ├── CONTEXT.md                  ← L2: shared agent router
          │   ├── variables.md                ← L3: project constants
          │   └── patterns.md                 ← L3: quality gates
          ├── backend/
          │   ├── CONTEXT.md                  ← L2: backend agent router
          │   └── backend-lead.md             ← L3: agent definition
          └── frontend/
              ├── CONTEXT.md                  ← L2: frontend agent router
              └── frontend-lead.md            ← L3: agent definition
  ```

  > **Adapt to your project**: Domain names (`features/`, `engineering/`, `infrastructure/`) are
  > examples. Use the domains that match your project. Define them in `CLAUDE.md`'s
  > `## Context Navigation` section during `contextsync setup`.

  ## Layer 3 Naming Conventions

  | Domain | Naming convention | Example |
  |---|---|---|
  | `features/` | `FEAT-{kebab-case}.md` prefix (required) | `FEAT-order-fulfillment.md` |
  | All other domains | Plain descriptive names (no prefix) | `architecture-overview.md` |

  ## Scaling: When Layer 2 Approaches 100 Lines

  When `docs/features/CONTEXT.md` fills up, split by sub-domain:

  ```
  docs/features/
    CONTEXT.md               ← routes to sub-domains only (not to individual guides)
    account-management/
      CONTEXT.md             ← routes to account feature guides
      FEAT-registration.md
      FEAT-profile.md
    payments/
      CONTEXT.md             ← routes to payment feature guides
      FEAT-checkout.md
      FEAT-refunds.md
  ```

  The 100-line limit drives this decomposition naturally — no upfront planning needed.
  ````

- [ ] **Step 5: Replace Navigation Scenario (lines 119–132)**

  Replace this block — including the `**Never**` line which must be preserved:
  ```markdown
  **Scenario**: Developer asks "How does user authentication work?"

  ```
  Step 1: Read CLAUDE.md           → confirms this is a feature question
  Step 2: Read /CONTEXT.md         → routes to docs/features/
  Step 3: Read docs/CONTEXT.md     → routes to docs/features/CONTEXT.md
  Step 4: Read docs/features/CONTEXT.md
                                   → routes to FEAT-user-authentication.md
  Step 5: Read FEAT-user-authentication.md  ← answer found
  ```

  **Never**: Jump directly to step 5. The chain exists to prevent reading stale or wrong files.
  ```

  With:
  ```markdown
  **Scenario**: Developer asks "How does user authentication work?"

  ```
  Step 1: Read CLAUDE.md                   → find ## Context Navigation → entry: docs/CONTEXT.md
  Step 2: Read docs/CONTEXT.md             → routes to docs/features/
  Step 3: Read docs/features/CONTEXT.md    → routes to FEAT-user-authentication.md
  Step 4: Read FEAT-user-authentication.md ← answer found
  ```

  **Never**: Jump directly to step 4. The chain exists to prevent reading stale or wrong files.
  ```

- [ ] **Step 6: Add Advanced note at the end of the file**

  Append after the last edge case section:

  ```markdown
  ---

  ## Advanced: Source-Mirror Mode (deferred)

  Placing CONTEXT.md files inside the source tree (e.g., `src/modules/orders/CONTEXT.md`)
  to mirror the code structure is a future opt-in mode. It is not implemented in the current
  version of this skill. All CONTEXT.md files belong inside `docs/` unless this mode is
  explicitly documented in your project's CLAUDE.md.
  ```

- [ ] **Step 7: Verify**

  Read `skills/contextsync/references/3-layer-system.md` and confirm:
  - Layer 1 shows `docs/CONTEXT.md` as entry point, no root `/CONTEXT.md`
  - Directory tree has no root-level `CONTEXT.md`
  - Navigation scenario starts at `docs/CONTEXT.md` (4 steps, not 5)
  - Navigation scenario ends with `**Never**: Jump directly to step 4.`
  - Layer 3 naming conventions table present
  - Scaling sub-domain pattern present
  - Advanced source-mirror note at end

- [ ] **Step 8: Commit**

  ```bash
  git add skills/contextsync/references/3-layer-system.md
  git commit -m "feat(contextsync): update 3-layer-system to docs-only default"
  ```

---

## Task 4: Update references/context-md-spec.md — Root Template

**Files:**
- Modify: `skills/contextsync/references/context-md-spec.md` lines 68–92

Only the "Root /CONTEXT.md" template section changes. The template heading and purpose text currently describe the root as the project router at project root. It now lives at `docs/CONTEXT.md`. The trailing `---` separator (line 92) must be preserved in the replacement.

- [ ] **Step 1: Verify acceptance criteria**

  After this edit, context-md-spec.md must show the Layer 1 template with:
  - Section heading `### Root docs/CONTEXT.md (domain router — Layer 1 entry point)` — not `Root /CONTEXT.md`
  - Purpose text that says `docs/CONTEXT.md` — not "project-level router"

- [ ] **Step 2: Replace the Root template section (lines 68–92, including trailing `---`)**

  Replace:
  ```markdown
  ### Root /CONTEXT.md (project router)

  ```markdown
  # {Your Project Name} — CONTEXT.md

  ## Purpose
  Project-level router for the {project name} codebase. Maps developer questions to the
  correct docs/ subdomain or feature guide.

  ## Files
  | File / Directory | Purpose |
  |---|---|
  | `docs/features/` | Feature guides — one per feature, covers flow, code, errors, config |
  | `docs/engineering/` | Architecture, module structure, conventions, open issues |
  | `docs/infrastructure/` | Deployment, cloud config, environment setup |
  | `docs/agents/` | Agent definitions for multi-agent workflows |

  ## When to Use
  - Starting a new task and need to orient to the codebase
  - Looking for documentation on a specific feature or capability
  - Searching for engineering or infrastructure documentation
  - Locating the agent definition for a specific role
  ```

  ---
  ```

  With:
  ````markdown
  ### Root `docs/CONTEXT.md` (domain router — Layer 1 entry point)

  ```markdown
  # {Your Project Name} — docs/CONTEXT.md

  ## Purpose
  Domain router for the {project name} documentation. Maps developer questions to the
  correct docs/ subdomain. Entry point declared in CLAUDE.md's ## Context Navigation section.

  ## Files
  | File / Directory | Purpose |
  |---|---|
  | `features/` | Feature guides — one per feature, covers flow, code, errors, config |
  | `engineering/` | Architecture, module structure, conventions, open issues |
  | `infrastructure/` | Deployment, cloud config, environment setup |
  | `agents/` | Agent definitions for multi-agent workflows |

  ## When to Use
  - Starting a new task and need to orient to the codebase
  - Looking for documentation on a specific feature or capability
  - Searching for engineering or infrastructure documentation
  - Locating the agent definition for a specific role
  ```

  > **Note**: Paths in the Files table are relative to `docs/`. Example: `features/` resolves
  > to `docs/features/CONTEXT.md`.

  ---
  ````

- [ ] **Step 3: Verify**

  Read lines 68–95 of `skills/contextsync/references/context-md-spec.md` and confirm:
  - Section heading says `docs/CONTEXT.md` not `Root /CONTEXT.md`
  - Template title is `# {Your Project Name} — docs/CONTEXT.md`
  - Purpose text mentions `## Context Navigation section`
  - Files table uses relative paths (`features/` not `docs/features/`)
  - Note about relative paths is present
  - `---` separator still present after the note

- [ ] **Step 4: Commit**

  ```bash
  git add skills/contextsync/references/context-md-spec.md
  git commit -m "feat(contextsync): update Layer 1 template to docs/CONTEXT.md entry point"
  ```

---

## Task 5: Create references/setup-guide.md

**Files:**
- Create: `skills/contextsync/references/setup-guide.md`

This is the file loaded when the skill runs the setup task. It must contain exactly the 5 sections defined in the spec. Section 3 must cover both branches of Step 3: (a) docs/ does not exist → ask for domain names, and (b) docs/ exists with subfolders → infer and confirm. Trailing slash normalization must be shown explicitly.

- [ ] **Step 1: Verify the file does not already exist**

  ```bash
  ls /Users/gauravporwal/Sites/projects/gp/dev-environment-setup/skills/contextsync/references/
  ```
  Expected: no `setup-guide.md` in the listing.

- [ ] **Step 2: Create the file**

  Create `skills/contextsync/references/setup-guide.md` with this exact content:

  ```markdown
  # contextsync Setup Guide

  ## Purpose

  This file is loaded when running the `contextsync setup` task. Follow the procedure
  below exactly. Do not skip steps. Do not run setup if CLAUDE.md does not exist.

  ---

  ## 1. When to Run Setup

  Run setup in these situations:
  - First time adopting contextsync on a project (no `## Context Navigation` in CLAUDE.md yet)
  - After adding a new app to a monorepo (new app needs its own docs scaffold)
  - After `## Context Navigation` was manually removed from CLAUDE.md
  - When some `docs/` structure exists but stubs are missing (setup fills gaps and writes bridge)

  Do NOT run setup to repair structure when `## Context Navigation` is already present —
  setup will detect the existing configuration, skip re-writing CLAUDE.md, and only create
  any missing stubs.

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

  **Trailing slash normalization**: If a user enters `web:apps/web/` (with trailing slash), it
  is normalized to `web:apps/web` before storing. Same for leading slashes. Example:
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

  ### Branch B — docs/ exists with subfolders (add a new app or re-run)

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

  (Steps 4 and 5 proceed as in Branch A for the new app.)

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
  ```

- [ ] **Step 3: Verify the file contents**

  Read `skills/contextsync/references/setup-guide.md` and confirm all 5 sections are present:
  - `## 1. When to Run Setup`
  - `## 2. Domain Naming Guidance` — table with ≥ 4 project types
  - `## 3. Monorepo Walkthrough` — both Branch A (docs/ missing) and Branch B (docs/ exists with subfolders)
  - `## 3` includes trailing slash normalization example
  - `## 4. Partial Structure Handling`
  - `## 5. Verifying the Setup` — 4-step verification procedure

- [ ] **Step 4: Commit**

  ```bash
  git add skills/contextsync/references/setup-guide.md
  git commit -m "feat(contextsync): add setup-guide.md with interactive setup procedure"
  ```

---

## Task 6: Acceptance Criteria Verification

Run through every acceptance criterion from the spec and confirm each is satisfied. This task reads files only — no file changes, no commit.

**Files:**
- Read: `skills/contextsync/SKILL.md`
- Read: `skills/contextsync/references/3-layer-system.md`
- Read: `skills/contextsync/references/context-md-spec.md`
- Read: `skills/contextsync/references/setup-guide.md`

- [ ] **Step 1: Check SKILL.md criteria**

  Read SKILL.md and verify each item:
  - [ ] Bootstrap section present before the 3-layer chain
  - [ ] Halt + warn when `## Context Navigation` absent (non-setup task)
  - [ ] App root derivation rule: "strip /docs/CONTEXT.md suffix"
  - [ ] Ambiguous monorepo: asks once with actual label names
  - [ ] Decision tree: "setup" branch is first
  - [ ] Decision tree: "## Context Navigation missing" branch is second
  - [ ] Reference table: `references/setup-guide.md` row present with load condition
  - [ ] Quality Gates note: references `docs/CONTEXT.md` not `/CONTEXT.md`
  - [ ] Hard Stop #1 narrowed: permits `## Context Navigation` writes by setup; still prohibits all other CLAUDE.md changes
  - [ ] setup-guide.md Section 1 explicitly states setup halts if CLAUDE.md does not exist

- [ ] **Step 2: Check 3-layer-system.md criteria**

  Read 3-layer-system.md and verify:
  - [ ] Layer 1 shows `docs/CONTEXT.md` as entry point — no root `/CONTEXT.md`
  - [ ] Directory tree: root has only `CLAUDE.md` and `docs/`, no root `CONTEXT.md`
  - [ ] Navigation scenario: 4 steps starting at `docs/CONTEXT.md`
  - [ ] Navigation scenario: ends with `**Never**: Jump directly to step 4.`
  - [ ] Layer 3 naming conventions table present
  - [ ] Sub-domain scaling pattern present
  - [ ] "Advanced: source-mirror" note at end

- [ ] **Step 3: Check context-md-spec.md criteria**

  Read context-md-spec.md and verify:
  - [ ] Root template section heading says `docs/CONTEXT.md` not `Root /CONTEXT.md`
  - [ ] Template title uses `docs/CONTEXT.md`
  - [ ] Files table in template uses relative paths (`features/` not `docs/features/`)
  - [ ] `---` separator present after the template block

- [ ] **Step 4: Check setup-guide.md criteria**

  Read setup-guide.md and verify:
  - [ ] Section 2 domain naming table present with ≥ 4 project types
  - [ ] Section 3 Branch A shows monorepo walkthrough with exact prompts and answers
  - [ ] Section 3 Branch B shows "docs/ exists with subfolders" → infer + confirm flow
  - [ ] Section 3 shows trailing slash normalization rule explicitly
  - [ ] Section 3 shows resulting CLAUDE.md output with labeled entries
  - [ ] Section 4 describes re-runnable repair behavior explicitly
  - [ ] Section 5 has a 4-step verification procedure

- [ ] **Step 5: Run git status**

  ```bash
  git status
  ```

  Expected: working tree clean (all changes committed in Tasks 1–5).
