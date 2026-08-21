# Skill Evaluation Framework

**Version**: 1.0
**Applies to**: Claude Code skills (`SKILL.md` + supporting files)
**Benchmark tiers**: Foundation → Production → Enterprise

---

## How to Use

Score each dimension independently. A dimension reaches a tier only when ALL criteria
for that tier AND all lower tiers are met. The overall skill tier is the tier reached
by the majority of dimensions (5 of 8).

### Tier Definitions

| Tier | Meaning |
|---|---|
| **Foundation** | Minimum viable. Skill loads and activates but has gaps that reduce reliability. |
| **Production** | Reliable. Skill consistently guides correct behavior across common scenarios. |
| **Enterprise** | Bulletproof. Skill resists rationalization, handles edge cases, and scales to any project. |

### Scoring Per Dimension

| Result | Points |
|---|---|
| Enterprise (all tiers met) | 3 |
| Production (Foundation + Production met) | 2 |
| Foundation only | 1 |
| Below Foundation | 0 |

**Maximum score**: 24 (8 dimensions × 3)

| Score | Overall Tier |
|---|---|
| 20–24 | Enterprise |
| 14–19 | Production |
| 8–13 | Foundation |
| 0–7 | Below Foundation |

---

## D1 — Claude Code Technical Compliance

Verifies the skill meets Claude Code's hard technical requirements.

| Criterion | Tier |
|---|---|
| `name` field exists in frontmatter | Foundation |
| `name` uses only letters, numbers, hyphens (no special chars) | Foundation |
| `description` field exists in frontmatter | Foundation |
| Frontmatter total ≤ 1024 characters | Foundation |
| `description` ≤ 500 characters | Production |
| `description` starts with "Use when..." | Production |
| `description` is written in third person | Production |
| No `@` force-load references anywhere in SKILL.md | Production |
| `SKILL.md` is at the skill directory root | Production |
| `description` does NOT summarize the skill's workflow or process steps | Enterprise |
| Supporting files use relative paths (no absolute paths) | Enterprise |
| Cross-references use skill name format, not file paths | Enterprise |

---

## D2 — Discoverability (CSO)

How well Claude can find and decide to activate this skill.

| Criterion | Tier |
|---|---|
| `description` contains at least 3 concrete trigger keywords/phrases | Foundation |
| `description` describes triggering conditions, not what the skill does | Foundation |
| Skill name is specific and memorable (not generic like "helper" or "tool") | Foundation |
| `description` covers both explicit triggers (keywords) and implicit triggers (context) | Production |
| Trigger keywords are technology-agnostic (unless skill is tech-specific) | Production |
| Keyword coverage includes synonyms (e.g., "stale / drift / outdated") | Production |
| Skill name uses active voice or gerund form (e.g., `context-sync` not `context-helper`) | Enterprise |
| `description` includes symptom-based triggers (describes the *problem*, not the *tool*) | Enterprise |
| Keywords match terms developers actually use, not internal jargon | Enterprise |

---

## D3 — Genericness (Project-Agnosticism)

How well the skill works across different projects, stacks, and teams.

| Criterion | Tier |
|---|---|
| No hardcoded project names anywhere in skill files | Foundation |
| No hardcoded absolute file paths in SKILL.md | Foundation |
| Worked examples use fictional/neutral projects | Foundation |
| Project-specific items (error source path, config source path) are explicitly flagged | Production |
| Project-specific config is delegated to `CLAUDE.md` or env vars | Production |
| No language/framework-specific code in SKILL.md (or clearly marked as examples) | Production |
| Feature naming conventions are configurable, not mandated | Production |
| Scripts/tools use configurable env vars for all project-specific values | Enterprise |
| Worked examples cover at least 2 different project types or domains | Enterprise |
| "Adapt to your project" callouts present where assumptions are unavoidable | Enterprise |

---

## D4 — Precision (No Loose Assumptions)

Whether every instruction is specific enough to execute without guessing.

| Criterion | Tier |
|---|---|
| All quality gates have an explicit fail action | Foundation |
| Decision tree covers the most common task types (≥ 5) | Foundation |
| No instructions that say "handle appropriately" or "as needed" without guidance | Foundation |
| All quality gates include a SKIP condition where applicable | Production |
| Output contract includes a concrete template | Production |
| Agent role references are either specific or clearly marked as examples | Production |
| Every cross-reference states *when* to load the file (not just what it contains) | Production |
| Output contract paths are marked as examples or configurable | Enterprise |
| All exception cases in navigation/execution have explicit handling instructions | Enterprise |
| No open-ended lists ("etc.", "and more") — all items enumerated | Enterprise |

---

## D5 — Completeness

Whether all necessary scenarios and components are covered.

| Criterion | Tier |
|---|---|
| Core task types covered in decision tree | Foundation |
| Quality gates defined | Foundation |
| At least one reference file or worked example present | Foundation |
| All files referenced in SKILL.md exist on disk | Production |
| Edge cases documented (missing files, broken chains, deprecated content) | Production |
| Full output contract defined (what the skill produces, in what format) | Production |
| Agent handoff schemas complete (inbound + outbound) if multi-agent | Production |
| Error/exception handling documented for every quality gate failure | Enterprise |
| Stub/fallback patterns defined for missing components | Enterprise |
| Deprecation handling pattern defined | Enterprise |
| Orphan file detection covered in audit process | Enterprise |

---

## D6 — Token Efficiency

Whether the skill is structured to minimize context window usage.

| Criterion | Tier |
|---|---|
| SKILL.md contains only core protocol — heavy reference in separate files | Foundation |
| "Load on demand" pattern used for reference files | Foundation |
| No copy-paste duplication between SKILL.md and reference files | Production |
| Progressive disclosure: reference files reference sub-files when content is large | Production |
| No `@` force-loads (which consume context before relevance is confirmed) | Production |
| SKILL.md ≤ 200 lines | Production |
| README and SKILL.md do not duplicate quality gates or key tables | Enterprise |
| Each reference file has a single clear loading condition | Enterprise |
| Supporting files only exist if content is > 50 lines or reusable as a tool | Enterprise |

---

## D7 — Anti-Pattern Compliance

Absence of known skill anti-patterns from the writing-skills spec.

| Criterion | Tier |
|---|---|
| No narrative storytelling ("in session X, we found...") | Foundation |
| No project-specific one-off solutions presented as general patterns | Foundation |
| No multi-language code examples (one language max per concept) | Production |
| Flowcharts used only for non-obvious decision points (not linear steps) | Production |
| All labels in flowcharts/diagrams have semantic meaning (no step1, helper2) | Production |
| Code examples are complete and runnable (not fill-in-the-blank templates) | Enterprise |
| Supporting files exist only for heavy reference (>100 lines) or reusable tools | Enterprise |
| One excellent worked example rather than multiple mediocre ones | Enterprise |

---

## D8 — Bulletproofing

How well the skill resists shortcuts, rationalizations, and edge-case failures.

| Criterion | Tier |
|---|---|
| At least 3 explicit "hard stops" or "never" rules defined | Foundation |
| CLAUDE.md (Layer 1) is explicitly marked read-only | Foundation |
| Deletion of documentation explicitly restricted | Foundation |
| Common rationalization paths are explicitly closed ("never skip X because...") | Production |
| Exception handling table covers broken chains, missing files, size violations | Production |
| Blocking vs. non-blocking failures clearly distinguished | Production |
| Escalation path defined when gates fail (fix vs. escalate) | Production |
| Rationalization table or "red flags" section present | Enterprise |
| Skill addresses "spirit vs. letter" arguments explicitly | Enterprise |
| Agents are told what NOT to infer when required fields are missing | Enterprise |

---

## Evaluation Template

Copy this when evaluating a skill:

```markdown
# Skill Evaluation: [skill-name]
**Date**: YYYY-MM-DD
**Evaluator**:
**Skill version / commit**:

## Scorecard

| Dimension | Tier Reached | Score | Key Issues |
|---|---|---|---|
| D1 — Technical Compliance | | /3 | |
| D2 — Discoverability | | /3 | |
| D3 — Genericness | | /3 | |
| D4 — Precision | | /3 | |
| D5 — Completeness | | /3 | |
| D6 — Token Efficiency | | /3 | |
| D7 — Anti-Pattern Compliance | | /3 | |
| D8 — Bulletproofing | | /3 | |
| **TOTAL** | | **/24** | |

**Overall Tier**: Foundation / Production / Enterprise

---

## Per-Dimension Detail

### D1 — Technical Compliance [score/3]
[criteria met / failed with specifics]

... (repeat for each dimension)

---

## Critical Issues (block Production)
[list items preventing Production tier]

## Improvement Recommendations
### To reach Production
- [ ] [specific action]

### To reach Enterprise
- [ ] [specific action]
```
