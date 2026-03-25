# Skill Evaluation: contextsync
**Date**: 2026-03-25
**Evaluator**: Claude Code (automated)
**Skill version**: Post-genericization (feat/skills branch)

---

## Scorecard

| Dimension | Tier Reached | Score | Key Issues |
|---|---|---|---|
| D1 — Technical Compliance | Enterprise | 3/3 | none |
| D2 — Discoverability | Enterprise | 3/3 | none |
| D3 — Genericness | Enterprise | 3/3 | none |
| D4 — Precision | Enterprise | 3/3 | none |
| D5 — Completeness | Enterprise | 3/3 | none |
| D6 — Token Efficiency | Enterprise | 3/3 | none |
| D7 — Anti-Pattern Compliance | Production | 2/3 | E7.1: code examples are fill-in-the-blank templates, not complete; E7.3: multiple worked examples of varying completeness |
| D8 — Bulletproofing | Enterprise | 3/3 | none |
| **TOTAL** | **Production–Enterprise** | **23/24** | |

---

## Per-Dimension Detail

### D1 — Technical Compliance [3/3 · Enterprise]

| Criterion | Result | Evidence |
|---|---|---|
| F1.1 name field exists | PASS | `name: contextsync` on line 2 of SKILL.md |
| F1.2 name uses only letters, numbers, hyphens | PASS | "contextsync" — all lowercase letters, no spaces or special characters |
| F1.3 description field exists | PASS | `description: >` block present on lines 3–8 of SKILL.md |
| F1.4 Frontmatter total <= 1024 characters | PASS | Frontmatter is 9 lines (lines 1–9), well under 1024 characters |
| P1.1 description <= 500 characters | PASS | Description is approximately 380 characters |
| P1.2 description starts with "Use when..." | PASS | Begins: "Use when context is stale, a feature is added or modified..." |
| P1.3 description is written in third person | PASS | "Use when context is stale... Also activate when receiving a handoff from another agent..." — no first-person pronouns |
| P1.4 No @ force-load references in SKILL.md | PASS | No `@` references found anywhere in SKILL.md |
| P1.5 SKILL.md is at the skill directory root | PASS | File is at `skills/contextsync/SKILL.md` |
| E1.1 description does NOT summarize the skill's workflow or process steps | PASS | Description lists triggers and conditions only; does not describe the 3-layer system or quality gates |
| E1.2 Supporting files use relative paths (no absolute paths) | PASS | All cross-references in SKILL.md use relative paths: `references/3-layer-system.md`, `references/agent-handoffs.md`, etc. No absolute paths found in any file |
| E1.3 Cross-references use skill name format, not file paths | PASS | Agent Collaboration section states "Handoff schemas are defined in `references/agent-handoffs.md`" — uses relative file path within the skill, which is the appropriate format for intra-skill references; no external skill cross-references present |

**Tier verdict**: Enterprise — all Foundation, Production, and Enterprise criteria pass cleanly.

---

### D2 — Discoverability [3/3 · Enterprise]

| Criterion | Result | Evidence |
|---|---|---|
| F2.1 description contains at least 3 concrete trigger keywords/phrases | PASS | "sync context", "update docs", "routing table", "CONTEXT.md", "feature guide", "docs are stale", "context drift", "documentation drift" — 8+ concrete keywords |
| F2.2 description describes triggering conditions, not what the skill does | PASS | The description is entirely trigger-based ("Use when context is stale", "when receiving a handoff", "when a PR review requires checking") — no description of internal workflow |
| F2.3 Skill name is specific and memorable | PASS | "contextsync" is a clear compound gerund — unambiguous, memorable, specific to its function |
| P2.1 description covers both explicit triggers (keywords) and implicit triggers (context) | PASS | Explicit: "sync context", "CONTEXT.md", "feature guide". Implicit: "a feature is added or modified", "files are renamed or deleted", "receiving a handoff from another agent" |
| P2.2 Trigger keywords are technology-agnostic | PASS | No language or framework names in the description. "feature guide", "routing table", "CONTEXT.md" are generic concepts |
| P2.3 Keyword coverage includes synonyms | PASS | "context drift" / "documentation drift" / "docs are stale" / "stale" all convey the same problem from different angles |
| E2.1 Skill name uses active voice or gerund form | PASS | "contextsync" is a gerund compound (context + sync) |
| E2.2 description includes symptom-based triggers (describes the problem) | PASS | "context is stale", "docs are stale", "context drift", "documentation drift" all describe the symptom, not the solution |
| E2.3 Keywords match terms developers actually use, not internal jargon | PASS | "update docs", "docs are stale", "routing table", "sync context" are natural developer phrases; "CONTEXT.md" is the system's own artifact name, which is appropriate |

**Tier verdict**: Enterprise — description is an exemplary trigger specification with both keyword and symptom coverage.

---

### D3 — Genericness [3/3 · Enterprise]

| Criterion | Result | Evidence |
|---|---|---|
| F3.1 No hardcoded project names anywhere in skill files | PASS | All worked examples use generic names: "order-fulfillment", "user-authentication", "payment-processing" — no real project names |
| F3.2 No hardcoded absolute file paths in SKILL.md | PASS | SKILL.md contains only relative paths and `{placeholder}` paths in templates |
| F3.3 Worked examples use fictional/neutral projects | PASS | feature-guide-spec.md uses "Order Fulfillment" — a canonical fictional project domain |
| P3.1 Project-specific items are explicitly flagged | PASS | Multiple `> **Project configuration**: ...` callouts in SKILL.md lines 88–90, feature-guide-spec.md lines 146–147, 168–169, and doc-auditor.md lines 12–17 |
| P3.2 Project-specific config is delegated to CLAUDE.md or env vars | PASS | G3/G4 source paths deferred to CLAUDE.md (SKILL.md lines 88–90); linter uses env vars: `LINT_DOCS_ROOT`, `LINT_FEATURE_PATTERN`, `LINT_FEATURE_DIR`, `LINT_CONTEXT_MAX_LINES` |
| P3.3 No language/framework-specific code in SKILL.md | PASS | SKILL.md contains no language-specific code; feature-guide-spec.md examples use `{placeholder}` syntax generics |
| P3.4 Feature naming conventions are configurable, not mandated | PASS | feature-guide-spec.md: "Feature guides follow the naming convention defined in your project's `CLAUDE.md`. Suggested default: `FEAT-{kebab-case-feature-name}.md`" — "suggested default" is not a mandate |
| E3.1 Scripts/tools use configurable env vars for all project-specific values | PASS | lint-doc-structure.sh uses `LINT_DOCS_ROOT`, `LINT_FEATURE_PATTERN`, `LINT_FEATURE_DIR`, `LINT_CONTEXT_MAX_LINES` with sensible defaults for all project-specific values |
| E3.2 Worked examples cover at least 2 different project types or domains | PASS | 3-layer-system.md covers: features, engineering, infrastructure, agents — four distinct domain types with different CONTEXT.md structures |
| E3.3 "Adapt to your project" callouts present where assumptions are unavoidable | PASS | 3-layer-system.md line 113: "> **Adapt to your project**: The domain names above...are examples." feature-guide-spec.md line 116: "> **Adapt to your project**: File paths and naming conventions should match your actual project structure." Multiple additional callouts in context-md-spec.md |

**Tier verdict**: Enterprise — genericization is thorough: env vars in scripts, CLAUDE.md delegation for paths, "Adapt to your project" callouts in all reference files, and neutral worked examples.

---

### D4 — Precision [3/3 · Enterprise]

| Criterion | Result | Evidence |
|---|---|---|
| F4.1 All quality gates have an explicit fail action | PASS | SKILL.md Quality Gates table: G1→"Split or trim before proceeding", G2→"Add missing sections with placeholder content", G3→"Remove unverified codes, mark [UNVERIFIED]", G4→"Remove unverified keys, mark [UNVERIFIED]", G5→"Mark [PATH UNVERIFIED] in docs", G6→"Create missing CONTEXT.md stubs" |
| F4.2 Decision tree covers >= 5 task types | PASS | Decision tree has 7 branches: new feature, modify feature, new error code, new config key, audit/stale docs, doc review/PR review, agent handoff |
| F4.3 No instructions that say "handle appropriately" or "as needed" without guidance | PASS | No such vague phrases found in SKILL.md or reference files |
| P4.1 All quality gates include a SKIP condition where applicable | PASS | Documentation Plan template explicitly shows G3 and G4 as "PASS / FAIL / SKIP"; agent-handoffs.md outbound schema also has `"G3_error_codes": "PASS | FAIL | SKIP"` and `"G4_config_keys": "PASS | FAIL | SKIP"` — the two gates where SKIP is applicable (no error codes / no config keys in scope) |
| P4.2 Output contract includes a concrete template | PASS | SKILL.md lines 99–136 provide a complete markdown template with all sections: Files to Create, Files to Update, CONTEXT.md Routing Changes, Quality Gate Pre-Check, Stale Entries Found, Cross-References to Verify |
| P4.3 Agent role references are either specific or clearly marked as examples | PASS | SKILL.md Agent Collaboration section states explicitly: "The roles below are **examples** — adapt role names to match your team's actual agent structure." Role examples use "e.g." notation throughout |
| P4.4 Every cross-reference states when to load the file | PASS | SKILL.md Reference Files table has a "Load When" column with explicit loading conditions for each of the 5 referenced files |
| E4.1 Output contract paths are marked as examples or configurable | PASS | Output contract uses paths like `` `docs/features/FEAT-feature-name.md` `` as illustrative examples, consistent with the FEAT-*.md naming convention described as a "suggested default" |
| E4.2 All exception cases have explicit handling instructions | PASS | SKILL.md Exception handling table covers 4 cases (missing CONTEXT.md, nonexistent file, circular reference, CONTEXT.md > 100 lines), all with specific actions. 3-layer-system.md adds 4 more edge cases with explicit handling |
| E4.3 No open-ended lists ("etc.", "and more") — all items enumerated | PASS | No "etc." or "and more" found in SKILL.md or reference files. All lists are closed enumerations |

**Tier verdict**: Enterprise — every gate has a fail action, SKIP conditions are correctly scoped to G3/G4 only, loading conditions are explicit, and exception handling is enumerated without vague delegation.

---

### D5 — Completeness [3/3 · Enterprise]

| Criterion | Result | Evidence |
|---|---|---|
| F5.1 Core task types covered in decision tree | PASS | 7 task types in decision tree covering all primary documentation workflows |
| F5.2 Quality gates defined | PASS | 6 quality gates (G1–G6) defined with IDs, conditions, and fail actions |
| F5.3 At least one reference file or worked example present | PASS | 4 reference files, 1 agent sub-file, 1 script, and a complete worked example in feature-guide-spec.md |
| P5.1 All files referenced in SKILL.md exist on disk | PASS | Verified: `references/3-layer-system.md`, `references/feature-guide-spec.md`, `references/context-md-spec.md`, `references/agent-handoffs.md`, `agents/doc-auditor.md` — all read successfully |
| P5.2 Edge cases documented | PASS | SKILL.md exception table + 3-layer-system.md Edge Cases section covers: missing CONTEXT.md, over-size CONTEXT.md, circular references, two CONTEXT.mds routing to same target, deprecated features |
| P5.3 Full output contract defined | PASS | Documentation Plan template (SKILL.md lines 99–136) plus full JSON handoff schemas in agent-handoffs.md |
| P5.4 Agent handoff schemas complete (inbound + outbound) | PASS | agent-handoffs.md defines 5 inbound schemas (implementer, specialist, reviewer, operations, coordinator) and 2 outbound schemas (task complete, audit report), plus shared types reference |
| E5.1 Error/exception handling documented for every quality gate failure | PASS | Every gate has a documented fail action in SKILL.md; Hard Stops section adds hard-stop rules beyond gates; agent-handoffs.md handoff protocol rule 4 covers gate failure reporting |
| E5.2 Stub/fallback patterns defined for missing components | PASS | context-md-spec.md provides a complete stub template for missing CONTEXT.md files (lines 144–167) |
| E5.3 Deprecation handling pattern defined | PASS | 3-layer-system.md lines 178–180: "Do not delete. Add a `> DEPRECATED as of [version]` callout at the top. Keep routing entry with `[DEPRECATED]` suffix in the purpose column." |
| E5.4 Orphan file detection covered in audit process | PASS | doc-auditor.md Pass 3: "Are there any files in docs/ NOT referenced in any CONTEXT.md? (orphan files)"; audit output format has a dedicated "Orphan Files" table section |

**Tier verdict**: Enterprise — no gaps found. All 11 criteria pass including stub patterns, deprecation handling, and orphan file detection.

---

### D6 — Token Efficiency [3/3 · Enterprise]

| Criterion | Result | Evidence |
|---|---|---|
| F6.1 SKILL.md contains only core protocol — heavy reference in separate files | PASS | SKILL.md has: identity, navigation protocol, decision tree, quality gates, output contract, reference index, agent collaboration, hard stops. Full specs for feature guides, CONTEXT.md authoring, 3-layer architecture, handoff schemas, and audit algorithm are all in separate reference files |
| F6.2 "Load on demand" pattern used for reference files | PASS | SKILL.md lines 140–149: explicit "Reference Files — load on demand, not all at once" table with "Load When" column |
| P6.1 No copy-paste duplication between SKILL.md and reference files | PASS | SKILL.md contains summaries and pointers; reference files contain the full specifications. Quality gate IDs appear in both but as cross-references, not duplicated content |
| P6.2 Progressive disclosure used for large reference content | PASS | Each reference file is loaded only for the specific sub-task that requires it; the full 3-layer spec, feature guide template, CONTEXT.md templates, and handoff schemas are all gated behind explicit loading conditions |
| P6.3 No @ force-loads | PASS | No `@` references found in any file |
| P6.4 SKILL.md <= 200 lines | PASS | SKILL.md is 176 lines |
| E6.1 README and SKILL.md do not duplicate quality gates or key tables | PASS | README.md (lines 59–68) repeats the quality gate table with Gate/Block columns only, omitting the Fail Action column. This is a brief summary reference table, not a full duplication — the full detail with fail actions is only in SKILL.md. Acceptable progressive disclosure. |
| E6.2 Each reference file has a single clear loading condition | PASS | Reference table in SKILL.md assigns exactly one loading condition per file. No reference file is loaded "generally" or "always" |
| E6.3 Supporting files only exist if content is > 50 lines or reusable as a tool | PASS | All 5 supporting files are either substantial (3-layer-system.md: 180 lines, feature-guide-spec.md: 277 lines, context-md-spec.md: 227 lines, agent-handoffs.md: 275 lines, doc-auditor.md: 176 lines) or are a reusable tool (lint-doc-structure.sh: 153 lines). Every file exceeds the 50-line threshold independently |

**Tier verdict**: Enterprise — the load-on-demand pattern is explicitly documented with a table, SKILL.md is 176 lines, and every supporting file earns its place by size.

---

### D7 — Anti-Pattern Compliance [2/3 · Production]

| Criterion | Result | Evidence |
|---|---|---|
| F7.1 No narrative storytelling | PASS | No narrative passages found. Identity section (SKILL.md lines 13–17) is 3 declarative statements, not a story |
| F7.2 No project-specific one-off solutions as general patterns | PASS | All patterns are generic; project-specific config explicitly deferred to CLAUDE.md |
| P7.1 No multi-language code examples | PASS | Code examples use generic `{placeholder}` syntax or bash. No examples showing the same thing in two languages |
| P7.2 Flowcharts used only for non-obvious decisions (not linear steps) | PASS | The decision tree in SKILL.md represents a branching structure (7 branches from the root), not linear steps. Navigation chain in 3-layer-system.md is a multi-level hierarchy, not a flowchart. No flowcharts for linear processes. |
| P7.3 All labels have semantic meaning (no step1, helper2) | PASS | All labels are semantic: G1–G6 (gate IDs with meaningful names), L1/L2/L3 (layer numbers with explicit layer names), task names like "document_feature", "audit_documentation" |
| E7.1 Code examples are complete (not fill-in-the-blank templates) | FAIL | feature-guide-spec.md contains explicit fill-in-the-blank templates throughout, e.g.: `` `src/{feature}/{feature}.controller.ts` ``, `create{Resource}`, `{RESOURCE}_NOT_FOUND`, `{FEATURE}_ENABLED`. While the worked example (Order Fulfillment) is complete, the Section templates themselves are parametric. This is a design choice for genericness but does not meet the letter of this criterion. |
| E7.2 Supporting files exist only for heavy reference or reusable tools | PASS | All supporting files are large (>150 lines) or a reusable tool (the linter script) |
| E7.3 One excellent worked example rather than multiple mediocre ones | FAIL | feature-guide-spec.md contains: (1) a short inline template per section, (2) an "Extended example with async processing" flow diagram, and (3) a "Complete Worked Example — Order Fulfillment". The section templates are parametric skeletons. The two examples (sync and async flow diagrams) are not clearly ordered by quality. The complete worked example is excellent, but the presence of multiple partial examples alongside it dilutes the principle. |

**Tier verdict**: Production — Foundation and Production criteria all pass. E7.1 fails because the Section templates in feature-guide-spec.md are explicitly fill-in-the-blank (using `{Resource}`, `{feature}`, `{FEATURE}` placeholders). E7.3 fails because there are multiple example types in feature-guide-spec.md rather than one canonical worked example with all others removed.

---

### D8 — Bulletproofing [3/3 · Enterprise]

| Criterion | Result | Evidence |
|---|---|---|
| F8.1 At least 3 explicit "hard stops" or "never" rules defined | PASS | SKILL.md Hard Stops section lists 5 numbered hard stops: (1) Modifying CLAUDE.md, (2) Undocumented error code, (3) CONTEXT.md content creep, (4) Deleting documentation, (5) Breaking the navigation chain |
| F8.2 CLAUDE.md (Layer 1) explicitly marked read-only | PASS | SKILL.md Navigation Protocol: "CLAUDE.md ← Layer 1: coding rules, conventions (READ ONLY)". Hard Stop #1: "Modifying CLAUDE.md — Layer 1 is read-only." Also stated in 3-layer-system.md lines 23–24 |
| F8.3 Deletion of documentation explicitly restricted | PASS | Hard Stop #4: "Deleting documentation — Update or extend only. Deletion requires explicit instruction + reason." Also in 3-layer-system.md structural rules table: "Deletions — Prohibited without explicit instruction" |
| P8.1 Common rationalization paths explicitly closed | PASS | agent-handoffs.md rule 3: "Never infer missing fields." agent-handoffs.md rule 1: "Parse before acting." Hard Stop #2 closes the rationalization of shipping unverified error codes. Hard Stop #3 closes the rationalization of writing explanation in CONTEXT.md. |
| P8.2 Exception handling table covers broken chains, missing files, size violations | PASS | SKILL.md exception table covers: missing CONTEXT.md, routing entry to nonexistent file, circular reference, CONTEXT.md > 100 lines. All four named exception types are covered |
| P8.3 Blocking vs. non-blocking failures clearly distinguished | PASS | Quality Gates table uses "block output until all pass". Audit report separates "Critical Issues (block delivery)" from "Warnings (non-blocking)" from "Debt Items (informational)". agent-handoffs.md rule 4 and 5 explicitly distinguish gate failures (complete_with_warnings) from debt items (informational) |
| P8.4 Escalation path defined when gates fail | PASS | SKILL.md: "Never deliver documentation output with a failing gate. Either fix it or escalate as a blocker." agent-handoffs.md defines escalation via `status: "blocked"` with structured `blockers` array to coordinator |
| E8.1 Rationalization table or "red flags" section present | PASS | Hard Stops section functions as an explicit anti-rationalization list. Each hard stop is written as a prohibition with a specific scenario to close ("Never ship a feature guide with...", "Update or extend only..."). agent-handoffs.md rule 3 explicitly closes the "infer missing fields" rationalization path |
| E8.2 Skill addresses "spirit vs. letter" arguments | PASS | Hard Stop #3: "CONTEXT.md content creep — Routing tables route. If you find yourself writing explanations in a CONTEXT.md, stop and move that content to a dedicated file." This addresses the rationalization that "a little explanation helps" — the spirit (routing only) is enforced as a letter rule |
| E8.3 Agents told what NOT to infer when required fields are missing | PASS | agent-handoffs.md rule 3: "Never infer missing fields: If a required field is missing from the inbound handoff schema, request clarification from the sending agent before proceeding." Also SKILL.md lines 88–90: "Never assume paths." for G3/G4 source configuration |

**Tier verdict**: Enterprise — 5 hard stops, read-only marking for CLAUDE.md, explicit deletion prohibition, blocking/non-blocking distinction, escalation path, and anti-rationalization rules all present and specific.

---

## Issues Summary

### Critical (block Production tier)
None — skill reaches Production on all dimensions.

### Gaps (block Enterprise tier)

**D7 — Anti-Pattern Compliance: E7.1 and E7.3**

**E7.1** — Code examples in `references/feature-guide-spec.md` are parametric templates, not complete examples. The Section 3 (Code Structure) template shows:
```
| `src/{feature}/{feature}.controller.ts` | HTTP endpoint definitions, request validation |
```
The Section 4 (Key Methods) template shows `create{Resource}`, `{Resource}Response`, etc. These are explicitly fill-in-the-blank. The complete worked example at the bottom of the file is an exception, but the section templates precede it and are the primary reference.

**E7.3** — `references/feature-guide-spec.md` contains three distinct example types: (1) per-section parametric templates with `{placeholder}` syntax, (2) an "Extended example with async processing" mid-file, and (3) a "Complete Worked Example — Order Fulfillment" at the end. This violates the principle of one excellent worked example. The parametric templates and the async flow diagram are separate from the single complete example, creating multiple partial examples of varying completeness alongside the one full one.

---

## Improvement Recommendations

### To reach Enterprise on all dimensions

| Dimension | Action | File to Edit |
|---|---|---|
| D7 (E7.1) | Replace per-section parametric templates with concrete examples from the Order Fulfillment worked example, moving the `{placeholder}` syntax into a separate "Adapt to your project" callout below each concrete example | `skills/contextsync/references/feature-guide-spec.md` |
| D7 (E7.3) | Consolidate the three example types: remove the standalone "Extended example with async processing" flow diagram (it is already covered in the complete worked example), and replace each section's parametric template with a concrete example drawn from the Order Fulfillment data | `skills/contextsync/references/feature-guide-spec.md` |
