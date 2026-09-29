---
id: 8wr.t.t8j
status: pending
priority: high
created_at: "2026-09-28 19:29:30"
estimate: medium
dependencies: []
tags: [ace-overseer, prune-safety, follow-up]
---
# Enforce prune-safety workflow contract in overseer prune orchestrator

## Origin

Independent correctness review (codex, `ace-review --preset code-valid`) of task
`8wj.t.ocz` (2026-09-28, finding 🔴 High): `8wj.t.ocz` strengthened the
**workflow text** (`ace-overseer/handbook/workflow-instructions/overseer.wf.md`)
so prune requires an executed preservation proof plus a no-active-writer check,
but the **pruner code** does not enforce it. This task closes that gap.

## Behavioral Specification

### Expected Behavior

- `ace-overseer prune` evaluates, per candidate, the same proofs the workflow
  mandates: preservation (ancestor containment, or verified destination with
  tree/artifact or patch equivalence) and no-active-writer (authoritative
  overseer/assignment/Lab lifecycle state).
- A missing, failed, or ambiguous proof blocks the candidate. `--force` must
  NOT bypass preservation or active-writer blocks; it may only override
  non-safety conveniences (e.g. dirty-tree confirmation), never the two
  non-negotiable proofs.
- Lab-runtime destruction delegates only after the in-flight Work check passes;
  an in-flight Lab work blocks destruction.

### Interface Contract

- Public CLI surface stays `ace-overseer prune [--dry-run|--yes] [targets...]`
  plus existing flags. New findings surface in `--dry-run` output as blocked
  candidates (ref, head SHA, missing proof kind).

### Success Criteria and Verification Plan

- [ ] SC1: Behavioral tests prove `--force` cannot bypass failed preservation or active-writer checks.
- [ ] SC2: Behavioral tests prove Lab prune blocks an in-flight Work.
- [ ] SC3: Patch-equivalence proof works across distinct source and successor repositories (fetch + separate bases, per overseer.wf.md).
- [ ] SC4: `ace-test ace-overseer all` green; workflow contract test and pruner behavior agree (no drift between overseer.wf.md and prune_orchestrator).

### Scope and Decisions

Owner: ace-overseer prune path (`prune_orchestrator.rb`, `prune.rb` CLI,
Lab client destruction path). Out of scope: workflow text changes (done in
8wj.t.ocz), Lab-engine generic removal (qk0). Reference evidence:
`.ace-tasks/8wj.t.ocz-ship-overseer-lifecycle-workflow-wfi-resolution/probe-evidence.md`.
