---
id: 8xb.t.k3v.1
status: draft
priority: medium
created_at: "2026-10-12 13:24:27"
estimate: M
dependencies: ["8xb.t.k3v.0"]
tags: []
parent: 8xb.t.k3v
bundle:
  presets: ["project"]
  files:
    - ".ace-tasks/8xb.t.k3v-measured-harness-evolution-for-ace/research-harness-learning-paper-and-gap-map.md"
  commands: []
---

# Emit execution feedback records from runs

## Behavioral Specification

### User Experience

- Input: a normal `ace-assign` / `ace-e2e` run; no extra user action required.
- Process: at run completion (success or failure), the tooling writes one standardized execution feedback record.
- Output: a machine-readable record under `.ace-local/<short-name>/feedback/` (ADR-029 short-name layout) that later loops (retro closure, comparative validation) can consume without human reformatting.

### Expected Behavior

Each record captures, at minimum:

- task/assignment identifier, workflow (harness) identifier + version/revision, runner context
- outcome (pass/fail), failure points (scenario, stage, error class), timing
- links to the full human-readable artifacts (report paths), not their contents

Behavioral rules:

- Records are emitted deterministically; identical runs produce identical schema.
- A failed or partially completed run still produces a record (failure data is the most valuable signal).
- Opt-out exists (config key in the gem's `.ace-defaults/`, cascade-resolvable per ADR-022).
- Records never contain secrets (respect ace-git-secrets threat model, ADR-025).

### Interface Contract

```bash
# No new required user command; emission is automatic on run completion.
# Config opt-out (cascade: CLI > project .ace/ > user ~/.ace/ > .ace-defaults/):
feedback:
  enabled: true        # default
  format: yaml         # deterministic schema
```

Error Handling:

- Write failures must not break the underlying run: record emission is best-effort with a warning.
- Corrupt/incomplete record files must be detectable (schema version field) and skippable by consumers.

Edge Cases:

- Concurrent runs from parallel worktrees → record filenames include run identifiers; no overwrites.
- Run interrupted via SIGINT → record emitted with interrupted status (exit 130 path).

## Success Criteria

- After any assign/E2E run, exactly one valid record exists for that run.
- A failing run produces a record containing its failure points.
- Opt-out config disables emission without affecting run results.

## Verification Plan

- Unit/component: record writer produces valid, schema-conformant output; failure path and SIGINT path covered.
- Integration: run an E2E scenario and observe the record; corrupt-record handling by the consumer path.
- Failure path: permission-denied feedback dir → run still succeeds with warning.

## Validation Questions

- Which gem owns the writer (ace-test-runner vs ace-assign) — decide at replan.
- Exact record schema fields; keep minimal v1 and version the schema from day one.
