---
id: 8xb.t.k3v.2
status: draft
priority: medium
created_at: "2026-10-12 13:24:27"
estimate: M
dependencies: ["8xb.t.k3v.0", "8xb.t.k3v.1"]
tags: []
parent: 8xb.t.k3v
bundle:
  presets: ["project"]
  files:
    - ".ace-tasks/8xb.t.k3v-measured-harness-evolution-for-ace/research-harness-learning-paper-and-gap-map.md"
  commands: []
---

# Close retro to harness edit loop

## Behavioral Specification

### User Experience

- Input: a completed retro (`ace-retro`) containing findings classified as harness/workflow failures.
- Process: for each such finding, the user (or agent via `as-retro-synthesize`) links the finding to a tracked harness-edit task — a task whose deliverable is one edit to a `*.wf.md` workflow or `SKILL.md` skill, with a verification criterion (e.g., the E2E scenario that previously failed).
- Output: a visible, queryable state: every harness-class finding is either linked to a harness-edit task or listed as open improvement debt.

### Expected Behavior

- A retro finding can reference a harness-edit task; the link is visible from both sides (finding shows its task; task shows its originating finding).
- Harness-class findings without a linked edit surface as improvement debt in retro status output.
- The harness-edit task inherits the ADR-034 (subtask 8xb.t.k3v.0) rules: one revision per finding, verification criterion mandatory, cascade promotion path noted.
- When a feedback record (8xb.t.k3v.1) exists for the failing run, the finding/task links to it as evidence.

### Interface Contract

```bash
# Behavioral surface (exact command shape decided at replan):
ace-retro link <finding-id> --task <task-id>   # link finding to harness-edit task
ace-retro status                                # shows unlinked harness-class findings as open debt
```

Error Handling:

- Linking to a nonexistent task or finding → actionable error naming which id was not found.
- Linking a finding that already has an active link → explicit replace-or-reject choice, never silent overwrite.

Edge Cases:

- Finding that maps to multiple candidate edits → ADR-034 rule applies: pick the single highest-value revision per cycle; the rest remain debt.
- Non-harness findings (product bugs, infra) → out of scope for this loop, classify accordingly.

## Success Criteria

- Creating a harness-class retro finding and linking a task works end to end; both artifacts show the link.
- `ace-retro status` distinguishes linked vs unlinked (debt) harness findings.
- A retro→edit→verification flow completed on a real historical retro demonstrates the full loop.

## Verification Plan

- Unit/component: linking, error cases, debt classification.
- Integration: replay one archived retro; verify debt visibility and link propagation.
- Failure path: invalid ids, double-link conflict.

## Validation Questions

- Does this belong in ace-retro CLI or in the `as-retro-*` skills as workflow instructions? (Lean CLI for state, skills for flow — confirm at replan.)
- Definition of "harness-class" finding: explicit classification field vs inference from content.
