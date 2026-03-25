# Agent Handoff Schemas

## Purpose

Defines the typed message contracts between the contextsync agent and other agents
in a multi-agent workflow. Load this file when receiving a task from another agent
or returning results to one.

> **Team configuration**: The role names below (`implementer`, `reviewer`, `operations`,
> `coordinator`) are generic labels. Replace them with your team's actual agent names
> (e.g., `tech-lead`, `backend-lead`, `qa-architect`, `sre`). Update the role names
> consistently across all inbound and outbound schemas.

---

## Inbound Handoffs — Messages received by Doc Engineer

### From Implementer → Doc Engineer

**Trigger**: Feature implementation is complete. Implementer needs documentation deliverables
before closing the implementation task.

```json
{
  "from": "implementer",
  "to": "contextsync",
  "task": "document_feature",
  "payload": {
    "feature_name": "string — kebab-case feature name",
    "feature_guide_path": "string — e.g. docs/features/FEAT-order-fulfillment.md",
    "changed_files": ["array of file paths modified in this feature"],
    "new_error_codes": ["array of new error code strings, empty if none"],
    "new_config_keys": ["array of new config key strings, empty if none"],
    "is_new_feature": "boolean — true = create guide, false = update existing",
    "context": "string — free text description of what was built",
    "priority": "blocking | normal"
  }
}
```

**Doc Engineer response** → see Outbound Handoffs section below.

---

### From Specialist (e.g. Backend Lead) → Doc Engineer

**Trigger**: Service interfaces are finalized. Specialist has the method signatures and
needs them documented in the feature guide's Key Methods section.

```json
{
  "from": "specialist",
  "to": "contextsync",
  "task": "document_service_interface",
  "payload": {
    "feature_name": "string",
    "source_file": "string — path to the primary service/module file",
    "methods": [
      {
        "name": "string — method name",
        "signature": "string — full method signature in project language",
        "description": "string — one-line description",
        "error_codes": ["array of error codes this method can throw"]
      }
    ]
  }
}
```

---

### From Reviewer (e.g. QA Lead) → Doc Engineer

**Trigger**: Test coverage is complete. Reviewer needs the feature guide to reflect test
coverage and known edge cases.

```json
{
  "from": "reviewer",
  "to": "contextsync",
  "task": "document_test_coverage",
  "payload": {
    "feature_name": "string",
    "test_file_paths": ["array of test file paths"],
    "coverage_notes": "string — what is and is not covered",
    "known_edge_cases": ["array of edge case descriptions to add to Error Cases section"],
    "missing_error_docs": ["array of error codes in tests not yet in feature guide"]
  }
}
```

---

### From Operations (e.g. SRE) → Doc Engineer

**Trigger**: Observability instrumentation is complete. Operations needs monitoring
information added to the feature guide.

```json
{
  "from": "operations",
  "to": "contextsync",
  "task": "document_observability",
  "payload": {
    "feature_name": "string",
    "metrics": [
      {
        "name": "string — metric name",
        "type": "counter | gauge | histogram",
        "description": "string"
      }
    ],
    "alert_thresholds": [
      {
        "metric": "string",
        "condition": "string — e.g. p99 > 2000ms",
        "severity": "warning | critical"
      }
    ],
    "log_patterns": ["array of important log message patterns to document"],
    "dashboard_links": ["array of monitoring dashboard URLs"]
  }
}
```

---

### From Coordinator (e.g. Tech Lead) → Doc Engineer — Audit Request

**Trigger**: Coordinator suspects documentation drift or wants a full doc health check.

```json
{
  "from": "coordinator",
  "to": "contextsync",
  "task": "audit_documentation",
  "payload": {
    "scope": "full | domain | feature",
    "domain": "string — if scope=domain, e.g. features",
    "feature": "string — if scope=feature, e.g. order-fulfillment",
    "checks": ["routing_integrity", "file_existence", "gate_compliance", "stale_entries"]
  }
}
```

---

## Outbound Handoffs — Messages sent by Doc Engineer

### Doc Engineer → Coordinator (Task Complete)

```json
{
  "from": "contextsync",
  "to": "coordinator",
  "task_completed": "document_feature | audit_documentation | document_service_interface",
  "status": "complete | complete_with_warnings | blocked",
  "deliverables": {
    "files_created": ["array of new file paths"],
    "files_updated": ["array of updated file paths"],
    "context_md_changes": [
      {
        "file": "path to CONTEXT.md",
        "rows_added": ["array of added routing rows"],
        "rows_removed": ["array of removed/stale rows"]
      }
    ]
  },
  "quality_gates": {
    "G1_context_size": "PASS | FAIL",
    "G2_required_sections": "PASS | FAIL",
    "G3_error_codes": "PASS | FAIL | SKIP",
    "G4_config_keys": "PASS | FAIL | SKIP",
    "G5_file_paths": "PASS | FAIL",
    "G6_chain_intact": "PASS | FAIL"
  },
  "warnings": ["array of non-blocking issues found and noted"],
  "blockers": [
    {
      "gate": "G3",
      "detail": "Error code ORDER_TIMEOUT referenced in feature but not found in project error source",
      "resolution_needed": "Implementer must add the error code to source before doc can be finalized"
    }
  ],
  "debt_items": [
    {
      "type": "missing_context_md | stale_entry | unverified_path",
      "location": "string",
      "detail": "string",
      "stub_created": true
    }
  ]
}
```

---

### Doc Engineer → Coordinator (Audit Report)

```json
{
  "from": "contextsync",
  "to": "coordinator",
  "task_completed": "audit_documentation",
  "status": "complete",
  "audit_summary": {
    "total_context_mds": 12,
    "context_mds_over_100_lines": 1,
    "stale_routing_entries": 3,
    "missing_context_mds": 2,
    "feature_guides_total": 8,
    "feature_guides_incomplete": 1
  },
  "issues": [
    {
      "severity": "critical | warning | info",
      "type": "stale_entry | missing_context_md | over_size_limit | missing_section | broken_chain",
      "location": "path to file",
      "detail": "string description",
      "recommended_action": "string"
    }
  ],
  "health_score": "integer 0-100 — percentage of passing checks"
}
```

---

## Shared Types Reference

```
// Task types
DocTask =
  | "document_feature"
  | "document_service_interface"
  | "document_test_coverage"
  | "document_observability"
  | "audit_documentation"
  | "update_feature"
  | "review_pr"

// Status
TaskStatus = "complete" | "complete_with_warnings" | "blocked"

// Priority
Priority = "blocking" | "normal"

// Gate result
GateResult = "PASS" | "FAIL" | "SKIP"

// Severity
IssueSeverity = "critical" | "warning" | "info"
```

---

## Handoff Protocol Rules

1. **Parse before acting**: When receiving a handoff, read the full JSON before starting
   any work. Extract `task`, `payload`, and `priority` first.

2. **Acknowledge blockers immediately**: If a blocker exists that prevents completing
   the task (e.g., error code not in source), send a partial response immediately with
   `status: "blocked"` rather than waiting until task completion.

3. **Never infer missing fields**: If a required field is missing from the inbound
   handoff schema, request clarification from the sending agent before proceeding.

4. **Gate failures block delivery**: A task with any G1–G6 gate failure returns
   `status: "complete_with_warnings"` with the failure detailed in `blockers`.
   The coordinator decides whether to ship with the warning or fix first.

5. **Debt items don't block delivery**: Stubs and debt logging are informational.
   They appear in `debt_items` but do not change the status to blocked.
