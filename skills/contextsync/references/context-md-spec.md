# CONTEXT.md Authoring Specification

## Purpose

This file defines the rules, templates, and patterns for creating and maintaining all
CONTEXT.md files across the documentation hierarchy. Load it whenever creating,
updating, or auditing any CONTEXT.md file.

---

## The One Rule

**CONTEXT.md files route. They do not explain.**

If you find yourself writing more than one sentence of explanation in a CONTEXT.md, stop.
Move that explanation to a dedicated content file and add a routing row.

---

## Size Limit

**Hard limit: 100 lines.**

This is not a guideline. A CONTEXT.md over 100 lines has become a content file wearing
a routing table's clothes. Trim it.

**When approaching 100 lines:**
1. Identify the rows with the most overlap in domain
2. Create a sub-CONTEXT.md for that subdomain
3. Replace the multiple rows with one row pointing to the sub-CONTEXT.md

---

## Mandatory Structure

Every CONTEXT.md must have exactly these four sections:

```markdown
# {Domain Name} — CONTEXT.md

## Purpose
[Exactly 1–2 sentences. What domain does this CONTEXT.md cover? What question does
navigating to this file answer?]

## Files
| File | Purpose |
|---|---|
| `file-name.md` | [One-line description of what question this file answers] |

## When to Use
- [Scenario that leads a developer to open this CONTEXT.md]
- [Scenario 2]
- [Scenario 3 — minimum 3 bullets, maximum 6]
```

**Rules:**
- Purpose: 1–2 sentences, no more
- Files table: one row per file, one-line purpose only
- When to Use: 3–6 bullets, written from the developer's question perspective
- No code blocks
- No diagrams
- No explanatory paragraphs

---

## Templates by Layer

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

### Domain CONTEXT.md (e.g., docs/features/CONTEXT.md)

```markdown
# Features — CONTEXT.md

## Purpose
Routes developer questions about project features to the correct feature guide.

## Files
| File | Purpose |
|---|---|
| `FEAT-user-authentication.md` | Authentication flow, JWT handling, session management |
| `FEAT-order-fulfillment.md` | Order lifecycle from placement to delivery |
| `FEAT-payment-processing.md` | Payment gateway integration, retry logic, refunds |

## When to Use
- Need to understand how a specific feature works end-to-end
- Writing or reviewing code for an existing feature
- Debugging unexpected behavior and need business rule reference
- Onboarding and need feature documentation
```

---

### Sub-domain CONTEXT.md (e.g., docs/agents/CONTEXT.md)

```markdown
# Agents — CONTEXT.md

## Purpose
Routes to the correct agent type subdirectory for agent definition files used
in multi-agent workflows.

## Files
| Directory | Purpose |
|---|---|
| `shared/` | Variables and patterns shared across all agent types |
| `backend/` | Backend specialist agent definitions |
| `frontend/` | Frontend specialist agent definitions |
| `infra/` | Operations and SRE agent definitions |

## When to Use
- Looking for a specific agent's persona, responsibilities, or output contract
- Onboarding a new agent to the workflow and need its definition file
- Auditing agent definitions for accuracy against current codebase
- Coordinator routing a task to the correct specialist agent
```

---

## Stub Template — For Missing CONTEXT.md

When you discover a CONTEXT.md is missing at any level, create this stub immediately
and log it as documentation debt before proceeding.

```markdown
# {Domain} — CONTEXT.md

## Purpose
[TODO: Fill in 1–2 sentence description of this domain.]

## Files
| File | Purpose |
|---|---|
| `[TODO: list files in this directory]` | [TODO: one-line purpose] |

## When to Use
- [TODO: Add 3+ scenarios that lead a developer here]

---
> ⚠️ STUB — This CONTEXT.md was auto-created as a navigation chain placeholder.
> Populated by: [agent/human name] on [date].
> Debt ticket: [link or ID if available]
```

---

## Quality Checklist

Before finalizing any CONTEXT.md, verify:

- [ ] ≤ 100 lines total
- [ ] Has exactly: Purpose, Files, When to Use sections
- [ ] Purpose is 1–2 sentences
- [ ] Every row in Files table points to a file/directory that exists
- [ ] When to Use has 3–6 bullets
- [ ] No explanatory prose, code blocks, or diagrams
- [ ] No rows pointing to STALE or deleted files

---

## Good vs. Bad Examples

### ❌ Bad — Content in routing table

```markdown
## Files
| File | Purpose |
|---|---|
| `order-fulfillment.md` | The order fulfillment feature manages the full lifecycle for
orders from creation through shipping and delivery. It handles cancellations and covers
auto-expiration logic which fires after 48 hours of inactivity. The PDF invoice generation
uses SFTP transfer to the client's document system. |
```

### ✅ Good — Routing only

```markdown
## Files
| File | Purpose |
|---|---|
| `order-fulfillment.md` | Full lifecycle state machine from placement to delivery |
```

---

### ❌ Bad — Wrong section (explanation in When to Use)

```markdown
## When to Use
- When you need to understand the order lifecycle. Note that this is different
  from the payment flow which happens after confirmation. The lifecycle covers
  states: PENDING, CONFIRMED, PROCESSING, SHIPPED, DELIVERED, CANCELLED.
```

### ✅ Good — Developer question perspective

```markdown
## When to Use
- Debugging an unexpected order state transition
- Writing a feature that reads or changes order status
- Onboarding and need to understand how orders progress through the system
```
