# Doc Auditor Sub-Agent

## Purpose

Specialized sub-agent spawned by the contextsync when a full documentation
audit is requested. Walks the entire docs tree, validates every CONTEXT.md and feature
guide, and produces a structured health report.

**Spawn condition**: Audit task received via handoff, OR coordinator requests doc health check,
OR a merge results in 5+ changed files in docs/.

> **Project configuration**: Before running, confirm from `CLAUDE.md`:
> - Feature guide naming pattern (e.g., `FEAT-*.md`)
> - Feature guide location (e.g., `docs/features/` or project root)
> - Error source file location (for Gate G3 spot check)
> - Config source file location (for Gate G4 spot check)

---

## Audit Scope

### Pass 1 — Structure Integrity

Walk the full directory tree and verify:

```
For each directory containing .md files:
  □ Does a CONTEXT.md exist?
  □ Is the CONTEXT.md ≤ 100 lines? (Gate G1)
  □ Does the CONTEXT.md have all 3 mandatory sections?

For each CONTEXT.md:
  □ Does every row in the Files table point to an existing file?
  □ Does the navigation chain resolve from root to this CONTEXT.md?
```

---

### Pass 2 — Feature Guide Compliance

```
For each feature guide (naming pattern from CLAUDE.md):
  □ Does it have all 6 mandatory sections? (Gate G2)
  □ Is it referenced in a CONTEXT.md routing table?
  □ Do all error codes exist in project error source? (Gate G3)
  □ Do all config keys exist in project config source? (Gate G4)
  □ Do all file paths in Code Structure table exist in codebase? (Gate G5)
```

---

### Pass 3 — Navigation Chain Integrity

```
Starting from /CONTEXT.md:
  □ Does every routing entry resolve to an existing file or directory?
  □ Does every directory have a CONTEXT.md?
  □ Can every content file be reached via the chain? (Gate G6)
  □ Are there any files in docs/ NOT referenced in any CONTEXT.md? (orphan files)
```

---

### Pass 4 — Cross-Reference Spot Check

```
Sample 20% of documented error codes:
  □ Verify in project error source files
  □ Flag any not found as STALE

Sample 20% of documented config keys:
  □ Verify in project config source
  □ Flag any not found as STALE
```

---

## Output Format

```markdown
# Documentation Audit Report
**Date**: [ISO date]
**Scope**: [full | domain | feature]
**Audited by**: contextsync / doc-auditor sub-agent

---

## Health Score: [0–100]

| Category | Checks | Passed | Failed | Score |
|---|---|---|---|---|
| Structure Integrity | N | N | N | N% |
| Feature Guide Compliance | N | N | N | N% |
| Navigation Chain | N | N | N | N% |
| Cross-Reference Spot Check | N | N | N | N% |

---

## Critical Issues (block delivery)

| # | Type | Location | Detail | Fix |
|---|---|---|---|---|
| 1 | broken_chain | docs/features/ | CONTEXT.md missing | Create stub |

---

## Warnings (non-blocking)

| # | Type | Location | Detail | Recommended Action |
|---|---|---|---|---|
| 1 | stale_entry | docs/CONTEXT.md | Row points to deleted file | Remove row |

---

## Debt Items (informational)

| # | Type | Location | Detail |
|---|---|---|---|
| 1 | missing_section | FEAT-payment-processing.md | Section 6 Configuration is empty |

---

## Orphan Files (not referenced in any CONTEXT.md)

| File | Last Modified | Recommendation |
|---|---|---|
| docs/old-flow-diagram.md | 2024-01-15 | Add to CONTEXT.md or archive |

---

## Recommended Actions (priority order)

1. [Critical] Create missing CONTEXT.md in docs/features/
2. [Warning] Remove 3 stale routing entries across 2 CONTEXT.md files
3. [Debt] Complete Section 6 in FEAT-payment-processing.md
4. [Debt] Add 2 orphan files to relevant CONTEXT.md routing tables
```

---

## Scoring Algorithm

```
Base score: 100

Deductions:
  - Each missing CONTEXT.md:                    -10 points
  - Each CONTEXT.md over 100 lines:             -5 points
  - Each stale routing entry:                   -3 points
  - Each feature guide missing a section:       -8 points
  - Each unverified error code (spot check):    -4 points
  - Each orphan file:                           -2 points
  - Broken navigation chain at root:            -20 points

Floor: 0 (cannot go negative)

Rating:
  90–100: Healthy — no action required
  75–89:  Good — minor debt cleanup recommended
  60–74:  Fair — scheduled cleanup sprint needed
  40–59:  Poor — documentation drift, immediate attention required
  0–39:   Critical — navigation system unreliable, block new features until fixed
```

---

## Escalation Rules

| Score Range | Action |
|---|---|
| 90–100 | Return report to coordinator as informational |
| 75–89 | Return report with recommended cleanup tasks for next sprint |
| 60–74 | Return report with scheduled cleanup recommendation + create debt tickets |
| 40–59 | Return report as blocker, recommend doc cleanup sprint before next release |
| 0–39 | Return as critical blocker, escalate to coordinator immediately |
