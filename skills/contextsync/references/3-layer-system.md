# 3-Layer Documentation System — Full Specification

## Purpose

This file is the authoritative spec for the project documentation architecture. Load it when
orienting to a new domain, auditing the overall structure, or explaining the system to
another agent.

---

## Layer Definitions

### Layer 1 — Root Configuration (READ ONLY)

```
CLAUDE.md          ← Coding rules, mandatory patterns, conventions
                      NEVER modify directly. Changes require human approval.

/CONTEXT.md        ← Project-level router. Maps developer questions to the
                      correct docs/ subfolder. Under 100 lines always.
```

**Rule**: CLAUDE.md is infrastructure config. Treat it like production environment variables —
you can read it, you can reference it, you cannot edit it without explicit sign-off.

---

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
├── CLAUDE.md                               ← L1: rules
├── CONTEXT.md                              ← L2: project router
│
└── docs/
    ├── CONTEXT.md                          ← L2: domain router
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

> **Adapt to your project**: The domain names above (`features/`, `engineering/`,
> `infrastructure/`) are examples. Use the domains that match your actual project structure.
> Define them in your root `/CONTEXT.md`.

---

## Navigation Chain — Step by Step

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
