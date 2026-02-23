# Phase F — Generate Report

## Purpose

Parse verifier output into a final report with YAML frontmatter for machine
parsing and a markdown body for human reading.

## Prerequisites

- Phase E completed (verifier-output.md exists)

## Steps

### 1. Parse verifier output

Extract from `reports/verifier-output.md`:
- Per-goal verdicts (PASS/FAIL with evidence)
- Final results line (`Results: X/8 passed`)

### 2. Generate report

Write `sandbox/reports/report.md` with this structure:

```markdown
---
test-id: TS-B36TS-001
title: "ace-b36ts Goal-Based E2E Pilot"
package: ace-b36ts
provider: claude:sonnet
timestamp: {{ISO 8601 timestamp}}
goals-passed: {{N}}
goals-failed: {{M}}
goals-total: 8
score: {{N/8 as decimal, e.g. 0.75}}
verdict: {{pass if 8/8, partial if 1-7, fail if 0}}
---

# E2E Report: ace-b36ts Goal-Based Pilot

**Score: N/8 (XX%)**  |  Provider: claude:sonnet  |  Date: {{YYYY-MM-DD}}

## Goal Results

{{per-goal sections from verifier output, reformatted as:}}

### Goal 1 — Help Survey: PASS
Evidence: ...

### Goal 2 — Encode Today: FAIL
Evidence: ...

(... all 8 goals ...)

## Summary

| Metric | Value |
|--------|-------|
| Passed | N |
| Failed | M |
| Total  | 8 |
| Score  | XX% |
```

### 3. Implementation approach

This can be done manually or with a small script that:

1. Reads `verifier-output.md`
2. Counts PASS/FAIL verdicts using grep
3. Computes score
4. Determines verdict: `pass` (8/8), `partial` (1-7), `fail` (0/8)
5. Assembles the report with frontmatter

```bash
SANDBOX_DIR="experiment/sandbox"
VERIFIER="$SANDBOX_DIR/reports/verifier-output.md"

passed=$(grep -c "**Verdict**: PASS" "$VERIFIER" || echo 0)
failed=$(grep -c "**Verdict**: FAIL" "$VERIFIER" || echo 0)
total=8
score=$(echo "scale=2; $passed / $total" | bc)
pct=$(echo "$passed * 100 / $total" | bc)
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
date_short=$(date -u +%Y-%m-%d)

if [ "$passed" -eq 8 ]; then
  verdict="pass"
elif [ "$passed" -eq 0 ]; then
  verdict="fail"
else
  verdict="partial"
fi

# Then assemble the report file with these values
```

## Outputs

- `sandbox/reports/report.md` — final E2E report with YAML frontmatter

## Report Schema

The YAML frontmatter fields:

| Field | Type | Description |
|-------|------|-------------|
| `test-id` | string | Test scenario ID |
| `title` | string | Human-readable title |
| `package` | string | Package under test |
| `provider` | string | LLM provider used |
| `timestamp` | string | ISO 8601 execution time |
| `goals-passed` | integer | Count of PASS verdicts |
| `goals-failed` | integer | Count of FAIL verdicts |
| `goals-total` | integer | Total goals (always 8) |
| `score` | float | goals-passed / goals-total |
| `verdict` | string | pass, partial, or fail |
