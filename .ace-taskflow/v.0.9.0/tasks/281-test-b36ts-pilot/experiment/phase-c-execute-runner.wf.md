# Phase C — Execute Runner

## Purpose

Invoke the runner agent via ace-llm with a CLI provider. The agent executes
all 8 goals sequentially, writing artifacts to `results/{1..8}/`.

## Prerequisites

- Phase A completed (sandbox exists with tooling on PATH)
- Phase B completed (runner-system.md and runner-prompt.md exist)

## Steps

### 1. Execute runner

```bash
cd experiment/sandbox

ace-llm claude:sonnet \
  --system "$(cat reports/runner-system.md)" \
  --prompt "$(cat reports/runner-prompt.md)" \
  --output reports/runner-output.md \
  --timeout 300
```

### 2. Verify artifacts

After execution, check that goal directories have content:

```bash
find results/ -type f | sort
```

Expected: at least one file per goal directory.

## Notes

- `claude:sonnet` invokes `claude -p` as a subprocess with full bash/tool access
- Timeout of 300 seconds (5 minutes) allows for sequential execution of all 8 goals
- Runner output (agent's response) is saved to `reports/runner-output.md`
- Actual artifacts are in `results/{1..8}/` directories

## Outputs

- `sandbox/reports/runner-output.md` — runner agent's response/summary
- `sandbox/results/{1..8}/` — populated with test artifacts
