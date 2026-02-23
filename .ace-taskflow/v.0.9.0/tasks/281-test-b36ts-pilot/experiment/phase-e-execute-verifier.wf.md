# Phase E — Execute Verifier

## Purpose

Invoke the verifier agent via ace-llm. The agent inspects runner artifacts
and renders PASS/FAIL verdicts for each goal.

## Prerequisites

- Phase D completed (verifier-system.md and verifier-prompt.md exist)

## Steps

### 1. Execute verifier

```bash
cd experiment/sandbox

ace-llm claude:sonnet \
  --system .cache/ace-e2e/verifier-system.md \
  --prompt .cache/ace-e2e/verifier-prompt.md \
  --output reports/verifier-output.md \
  --timeout 120
```

### 2. Inspect results

```bash
cat reports/verifier-output.md
```

Expected: per-goal PASS/FAIL verdicts with evidence, ending with `**Results: X/8 passed**`.

## Notes

- Timeout of 120 seconds (2 minutes) — verifier only inspects text, no tool execution
- The verifier sees only the artifact snapshot from phase D, not the live filesystem
- This is intentional: verifier judges what the runner produced, not what exists now

## Outputs

- `sandbox/reports/verifier-output.md` — per-goal PASS/FAIL verdicts
