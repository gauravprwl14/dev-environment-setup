# contextsync

**Context Synchronization + 3-Layer Routing Agent**

A Claude Code agent skill that owns the full CONTEXT.md chain for any software project.
Keeps context synchronized with every code change, maintains routing tables across all
3 layers, writes and validates feature guides, and integrates with multi-agent workflows
via typed handoff schemas.

Designed to be project-agnostic — works with any language, framework, or team structure.

---

## Skill Structure

```
contextsync/
│
├── SKILL.md                        ← Agent identity, navigation protocol, task decision
│                                     tree, quality gates, output contract, reference index
│
├── references/
│   ├── 3-layer-system.md           ← Full 3-layer architecture spec, directory template,
│   │                                 domain ownership pattern, edge case handling
│   │
│   ├── feature-guide-spec.md       ← Required section template, authoring rules,
│   │                                 worked example (generic feature)
│   │
│   ├── context-md-spec.md          ← CONTEXT.md authoring rules, templates by layer,
│   │                                 stub pattern, good/bad examples
│   │
│   └── agent-handoffs.md           ← Typed JSON schemas for agent interactions
│                                     (configurable roles per team)
│
├── agents/
│   └── doc-auditor.md              ← Sub-agent for full documentation tree audits,
│                                     health scoring algorithm, escalation rules
│
└── scripts/
    └── lint-doc-structure.sh       ← Bash linter: validates CONTEXT.md sizes, section
                                      compliance, file path existence, navigation chain
```

---

## Activation Triggers

The skill activates when any of these are mentioned:

- "sync context" / "context drift" / "routing table is stale" / "update docs"
- "CONTEXT.md" / "feature guide" / "docs directory"
- New feature implementation complete (from implementer handoff)
- Error code or config key added/changed
- "audit docs" / "doc health check" / "documentation drift"

---

## Quality Gates

| ID | Gate | Block? |
|---|---|---|
| G1 | CONTEXT.md ≤ 100 lines | Yes |
| G2 | Feature guide has all required sections | Yes |
| G3 | Error/exception codes verified in project source | Yes |
| G4 | Config keys verified in project source | Yes |
| G5 | File paths exist in codebase | Yes |
| G6 | Navigation chain unbroken | Yes |

---

## Running the Linter

```bash
# Full docs tree
./scripts/lint-doc-structure.sh

# Specific domain
./scripts/lint-doc-structure.sh docs/your-domain

# Specific feature guide
./scripts/lint-doc-structure.sh --feature docs/features/FEAT-my-feature.md

# Exit codes: 0=healthy, 1=warnings, 2=critical failures
```

---

## Project Setup

When adopting this skill for a new project:

1. Define your feature guide naming convention in `CLAUDE.md` (default: `FEAT-*.md`)
2. Confirm error source location in `CLAUDE.md` (used by Gate G3)
3. Confirm config source location in `CLAUDE.md` (used by Gate G4)
4. Create your root `/CONTEXT.md` using the template in `references/context-md-spec.md`
5. Configure agent role names in `references/agent-handoffs.md` to match your team
