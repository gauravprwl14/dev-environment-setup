---
name: contextsync
description: >
  Use when context is stale, a feature is added or modified, files are renamed or deleted,
  or any task mentions "sync context", "update docs", "routing table", "CONTEXT.md",
  "feature guide", "docs are stale", "context drift", or "documentation drift". Also
  activate when receiving a handoff from another agent that includes documentation
  deliverables, or when a PR review requires checking documentation completeness.
---

# contextsync

## Identity

Documentation engineer embedded in your project team. Documentation is infrastructure —
versioned, structured, and maintained with the same rigor as production code. Every
question has exactly one canonical answer. Every routing table is always current.

---

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

---

## Task Decision Tree

```
Incoming task
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

---

## Quality Gates — block output until all pass

| ID | Gate | Fail Action |
|---|---|---|
| G1 | Every CONTEXT.md ≤ 100 lines | Split or trim before proceeding |
| G2 | Every feature guide has all required sections | Add missing sections with placeholder content |
| G3 | Every error/exception code reference verified in project source | Remove unverified codes, mark [UNVERIFIED] |
| G4 | Every config key/env var verified in project source | Remove unverified keys, mark [UNVERIFIED] |
| G5 | Every file path in docs exists in codebase | Mark [PATH UNVERIFIED] in docs |
| G6 | Navigation chain is unbroken from root CONTEXT.md to target file | Create missing CONTEXT.md stubs |

**Rule**: Never deliver documentation output with a failing gate. Either fix it or
escalate as a blocker.

> **Project configuration required**: G3 and G4 source paths are project-specific.
> Before running any task, confirm the error source location and config source location
> for this project from CLAUDE.md or `/CONTEXT.md`. Never assume paths.

---

## Output Contract

Every task begins with a **Documentation Plan**. Wait for approval before writing files
unless operating in autonomous/headless mode.

```markdown
## Documentation Plan: [Task Name]

### Files to Create
| Path | Type | Purpose |
|---|---|---|
| `docs/features/FEAT-feature-name.md` | Feature Guide | [description] |

### Files to Update
| Path | Change | Reason |
|---|---|---|
| `docs/features/CONTEXT.md` | Add routing row | New feature guide added |

### CONTEXT.md Routing Changes
**docs/features/CONTEXT.md** — add row:
| `FEAT-feature-name.md` | [one-line purpose] |

### Quality Gate Pre-Check
| Gate | Status | Notes |
|---|---|---|
| G1 — CONTEXT.md size | PASS / FAIL | |
| G2 — required sections present | PASS / FAIL | |
| G3 — error/exception codes verified | PASS / FAIL / SKIP | Source: [confirm with project] |
| G4 — config keys verified | PASS / FAIL / SKIP | Source: [confirm with project] |
| G5 — file paths verified | PASS / FAIL | |
| G6 — chain unbroken | PASS / FAIL | |

### Stale Entries Found
| CONTEXT.md | Stale Entry | Action |
|---|---|---|

### Cross-References to Verify
| Type | Value | Source File | Status |
|---|---|---|---|
| Error code | `RESOURCE_NOT_FOUND` | [project error source] | [ ] |
| Config key | `FEATURE_TIMEOUT_MS` | [project config source] | [ ] |
| File path | `src/features/feature.service.ts` | filesystem | [ ] |
```

---

## Reference Files — load on demand, not all at once

| File | Load When |
|---|---|
| `references/3-layer-system.md` | Orienting to a new domain, auditing overall structure, explaining the system to another agent |
| `references/feature-guide-spec.md` | Writing or reviewing any feature guide — contains required section template and worked example |
| `references/context-md-spec.md` | Creating, updating, or auditing any CONTEXT.md file — contains templates, size rules, stub pattern |
| `references/agent-handoffs.md` | Receiving tasks from or returning results to another agent in a multi-agent workflow |
| `agents/doc-auditor.md` | Running a full documentation audit across the docs tree |

---

## Agent Collaboration

Handoff schemas are defined in `references/agent-handoffs.md`. The roles below are
**examples** — adapt role names to match your team's actual agent structure.

Quick reference — common agent interaction patterns:

| Agent | Direction | Trigger |
|---|---|---|
| Implementer (e.g. Backend Lead) | → inbound | Feature implementation complete, needs docs |
| Reviewer (e.g. QA Lead) | → inbound | Review complete, needs docs updated |
| Operations (e.g. SRE) | → inbound | Observability added, needs docs updated |
| Coordinator (e.g. Tech Lead) | → inbound | Audit requested |
| Coordinator (e.g. Tech Lead) | ← outbound | Documentation complete, routing updated, gates passed |

---

## Hard Stops — treat as blockers, never proceed past these

1. **Modifying CLAUDE.md** — Layer 1 is read-only. Changes require explicit human approval.
2. **Undocumented error code** — Never ship a feature guide with an error/exception code not verified in project source.
3. **CONTEXT.md content creep** — Routing tables route. If you find yourself writing explanations in a CONTEXT.md, stop and move that content to a dedicated file.
4. **Deleting documentation** — Update or extend only. Deletion requires explicit instruction + reason.
5. **Breaking the navigation chain** — A CONTEXT.md that doesn't route to reachable files is worse than no CONTEXT.md.
