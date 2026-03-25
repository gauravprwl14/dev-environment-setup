#!/usr/bin/env bash
# lint-doc-structure.sh
# contextsync — Structure Linter
#
# Usage:
#   ./scripts/lint-doc-structure.sh                         # lint full docs/ tree
#   ./scripts/lint-doc-structure.sh docs/features           # lint a specific domain
#   ./scripts/lint-doc-structure.sh --feature FEAT-name.md  # lint a specific feature guide
#
# Exit codes:
#   0 = all checks passed
#   1 = warnings found (non-blocking)
#   2 = critical failures found (blocking)
#
# Project configuration:
#   Set these variables to match your project before running.
#   Alternatively, source a project-specific config file:
#     source .lint-doc-config && ./scripts/lint-doc-structure.sh

set -euo pipefail

# ─── Project Configuration ─────────────────────────────────────────────────────
# Override these for your project:
DOCS_ROOT="${LINT_DOCS_ROOT:-docs}"
FEATURE_GUIDE_PATTERN="${LINT_FEATURE_PATTERN:-FEAT-*.md}"
FEATURE_GUIDE_DIR="${LINT_FEATURE_DIR:-.}"  # directory containing feature guides
CONTEXT_MAX_LINES="${LINT_CONTEXT_MAX_LINES:-100}"

# ─── Counters ──────────────────────────────────────────────────────────────────
PASS=0
WARN=0
FAIL=0

# ─── Helpers ───────────────────────────────────────────────────────────────────
pass() { echo "  ✅ PASS: $1"; ((PASS++)); }
warn() { echo "  ⚠️  WARN: $1"; ((WARN++)); }
fail() { echo "  ❌ FAIL: $1"; ((FAIL++)); }
header() { echo ""; echo "── $1 ──────────────────────────────────────────"; }

# ─── Gate G1: CONTEXT.md size ──────────────────────────────────────────────────
header "Gate G1 — CONTEXT.md Size (max ${CONTEXT_MAX_LINES} lines)"

find "${DOCS_ROOT}" -name "CONTEXT.md" 2>/dev/null | while read -r ctx; do
  lines=$(wc -l < "$ctx")
  if [ "$lines" -gt "$CONTEXT_MAX_LINES" ]; then
    fail "${ctx} is ${lines} lines (limit: ${CONTEXT_MAX_LINES})"
  else
    pass "${ctx} — ${lines} lines"
  fi
done

# Also check root CONTEXT.md
if [ -f "CONTEXT.md" ]; then
  lines=$(wc -l < "CONTEXT.md")
  if [ "$lines" -gt "$CONTEXT_MAX_LINES" ]; then
    fail "CONTEXT.md (root) is ${lines} lines (limit: ${CONTEXT_MAX_LINES})"
  else
    pass "CONTEXT.md (root) — ${lines} lines"
  fi
fi

# ─── Gate G2: Feature guide required sections ──────────────────────────────────
header "Gate G2 — Feature Guide Section Compliance"

REQUIRED_SECTIONS=(
  "## Business Use Case"
  "## Flow Diagram"
  "## Code Structure"
  "## Key Methods"
  "## Error Cases"
  "## Configuration"
)

find "${FEATURE_GUIDE_DIR}" -maxdepth 2 -name "${FEATURE_GUIDE_PATTERN}" 2>/dev/null | while read -r guide; do
  missing=0
  for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "^${section}" "$guide"; then
      warn "${guide} — missing section: ${section}"
      ((missing++))
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "${guide} — all 6 sections present"
  else
    fail "${guide} — ${missing} section(s) missing"
  fi
done

# ─── Gate G5: File paths in docs exist ────────────────────────────────────────
header "Gate G5 — File Path Verification in CONTEXT.md Tables"

find . -name "CONTEXT.md" | while read -r ctx; do
  ctx_dir=$(dirname "$ctx")
  # Extract file references from markdown table rows (backtick-wrapped paths)
  grep -oP '`[^`]+\.(md|ts|js|py|go|java|json|yaml|yml)`' "$ctx" 2>/dev/null | tr -d '`' | while read -r ref; do
    # Resolve relative to CONTEXT.md directory
    full_path="${ctx_dir}/${ref}"
    if [ ! -e "$full_path" ]; then
      fail "${ctx} → stale reference: ${ref} (resolved: ${full_path})"
    else
      pass "${ctx} → ${ref} exists"
    fi
  done
done

# ─── Gate G6: Navigation chain — every directory has a CONTEXT.md ──────────────
header "Gate G6 — Navigation Chain Integrity"

find "${DOCS_ROOT}" -type d 2>/dev/null | while read -r dir; do
  if [ ! -f "${dir}/CONTEXT.md" ]; then
    warn "Missing CONTEXT.md in: ${dir}"
  else
    pass "CONTEXT.md present: ${dir}"
  fi
done

# ─── CONTEXT.md mandatory sections check ───────────────────────────────────────
header "CONTEXT.md Mandatory Sections (Purpose / Files / When to Use)"

find . -name "CONTEXT.md" | while read -r ctx; do
  missing_sections=0
  for section in "## Purpose" "## Files" "## When to Use"; do
    if ! grep -q "^${section}" "$ctx"; then
      warn "${ctx} — missing: ${section}"
      ((missing_sections++))
    fi
  done
  if [ "$missing_sections" -eq 0 ]; then
    pass "${ctx} — all 3 mandatory sections present"
  fi
done

# ─── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════"
echo "  Documentation Lint Summary"
echo "════════════════════════════════════════════"
echo "  ✅ PASS:    ${PASS}"
echo "  ⚠️  WARN:    ${WARN}"
echo "  ❌ FAIL:    ${FAIL}"
echo "════════════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
  echo "  Result: CRITICAL — ${FAIL} blocking issue(s) found"
  exit 2
elif [ "$WARN" -gt 0 ]; then
  echo "  Result: WARNING — ${WARN} non-blocking issue(s) found"
  exit 1
else
  echo "  Result: HEALTHY — all checks passed"
  exit 0
fi
