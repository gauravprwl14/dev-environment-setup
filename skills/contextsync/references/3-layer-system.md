# 3-Layer Documentation System — Full Specification

## Purpose

This file is the authoritative spec for the project documentation architecture. Load it when
orienting to a new domain, auditing the overall structure, or explaining the system to
another agent.

---

## Layer Definitions

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

---

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

---

### Layer 3 — Content Files

```
docs/features/
  ├── FEAT-user-authentication.md
  ├── FEAT-order-fulfillment.md
  └── FEAT-payment-processing.md

docs/engineering/
  ├── architecture-overview.md
  └── module-patterns.md

docs/infrastructure/
  ├── deployment-config.md
  └── environment-setup.md

docs/agents/{type}/
  ├── variables.md         ← shared project constants
  ├── patterns.md          ← quality gates and patterns
  └── {role}-agent.md      ← agent definition files
```

---

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

### Layer 3 Naming Conventions

| Domain | Naming convention | Example |
|---|---|---|
| `features/` | `FEAT-{kebab-case}.md` prefix (required) | `FEAT-order-fulfillment.md` |
| All other domains | Plain descriptive names (no prefix) | `architecture-overview.md` |

### Scaling — When Layer 2 Approaches 100 Lines

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

---

## Navigation Chain — Step by Step

**Scenario**: Developer asks "How does user authentication work?"

```
Step 1: Read CLAUDE.md                   → find ## Context Navigation → entry: docs/CONTEXT.md
Step 2: Read docs/CONTEXT.md             → routes to docs/features/
Step 3: Read docs/features/CONTEXT.md    → routes to FEAT-user-authentication.md
Step 4: Read FEAT-user-authentication.md ← answer found
```

**Never**: Jump directly to step 4. The chain exists to prevent reading stale or wrong files.

---

## Domain Ownership Map (example — adapt to your team)

| Domain | CONTEXT.md Location | Owned By |
|---|---|---|
| Feature Guides | `docs/features/CONTEXT.md` | Doc Engineer |
| Engineering Docs | `docs/engineering/CONTEXT.md` | Tech Lead + Doc Engineer |
| Infrastructure | `docs/infrastructure/CONTEXT.md` | SRE/Ops + Doc Engineer |
| Agent Definitions | `docs/agents/CONTEXT.md` | Tech Lead + Doc Engineer |

> Define your actual domain ownership in `CLAUDE.md`.

---

## Structural Rules Summary

| Rule | Detail |
|---|---|
| CONTEXT.md max size | 100 lines hard limit |
| CONTEXT.md content | Routing only — no explanations, no code |
| Feature guide location | Defined per project (e.g. `docs/features/` or project root) |
| Feature guide naming | Defined in CLAUDE.md (suggested default: `FEAT-{feature-name}.md`) |
| Agent definition location | `docs/agents/{type}/{role}.md` |
| Deletions | Prohibited without explicit instruction |
| CLAUDE.md edits | Prohibited without human approval |

---

## Edge Cases and How to Handle Them

### Missing CONTEXT.md
Create a stub immediately using the template in `context-md-spec.md`. Log it as documentation
debt. Do not skip the layer — an empty CONTEXT.md is better than a broken chain.

### CONTEXT.md over 100 lines
Split content into a new dedicated file. The CONTEXT.md keeps only the routing row to that
new file. Example: a CONTEXT.md with 40 rows can split into two domain-specific CONTEXT.md
files with a parent routing between them.

### Two CONTEXT.md files routing to the same target
Acceptable if the target genuinely belongs to both domains. Document it explicitly in both
routing tables so audits don't flag it as an error.

### Feature guide for a deprecated feature
Do not delete. Add a `> ⚠️ DEPRECATED as of [version]` callout at the top. Keep routing
entry with `[DEPRECATED]` suffix in the purpose column.

---

## Advanced: Source-Mirror Mode (deferred)

Placing CONTEXT.md files inside the source tree (e.g., `src/modules/orders/CONTEXT.md`)
to mirror the code structure is a future opt-in mode. It is not implemented in the current
version of this skill. All CONTEXT.md files belong inside `docs/` unless this mode is
explicitly documented in your project's CLAUDE.md.
