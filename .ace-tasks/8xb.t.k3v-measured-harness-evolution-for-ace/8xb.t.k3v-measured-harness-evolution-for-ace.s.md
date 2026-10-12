---
id: 8xb.t.k3v
status: draft
priority: medium
created_at: "2026-10-12 13:24:18"
estimate: TBD
dependencies: []
tags: []
bundle:
  presets: ["project"]
  files:
    - ".ace-tasks/8xb.t.k3v-measured-harness-evolution-for-ace/research-harness-learning-paper-and-gap-map.md"
  commands: []
---

# Measured Harness Evolution for ACE

## Objective

Make harness improvement in ACE measurable and closed-loop, inspired by "Harness Learning Enables Generalizable Test-Time Adaptation" (arXiv:2609.35738). The paper shows the harness is a distinct, improvable layer whose revision quality transfers to unseen tasks — and that single evidence-gated revisions work reliably while unbounded revision sequences do not. ACE already improves its harness (workflows, skills) manually; this task turns that craft into a measured loop: evidence → revision → comparative validation → cascade promotion.

Full research and the gap map: [research-harness-learning-paper-and-gap-map.md](research-harness-learning-paper-and-gap-map.md).

## Scope of Work

- User experience scope: retro findings lead to tracked harness edits; workflow changes can be validated comparatively; every run leaves a reusable evidence record.
- System behavior scope: feedback record emission on assign/E2E runs; retro↔edit linking with debt visibility; comparative validation in `ace-sim`.
- Interface scope: one new ADR; config keys for feedback emission; `ace-retro` link/status surface; `ace-sim` compare surface (exact shapes at replan).

## Vertical Slice Decomposition (task/subtask model)

| Slice | Outcome (end cap) | Size | Verification intent |
|-------|-------------------|------|---------------------|
| 8xb.t.k3v.0 | ADR "Measured Harness Evolution" accepted, decisions.md updated | S | Decision governs all gaps 1–4; lint/ADR conventions pass |
| 8xb.t.k3v.1 | Every assign/E2E run emits a valid, deterministic feedback record | M | Unit + integration incl. failure/SIGINT paths |
| 8xb.t.k3v.2 | Retro harness findings link to edit tasks; unlinked = visible debt | M | Replay a real archived retro end to end |
| 8xb.t.k3v.3 | Comparative old-vs-new workflow report with adopt/reject recommendation | L | Real two-variant comparison over fixed task set |

Ordering: 0 → 1 → 2 → 3. Slice 0 is the riskiest-path validator (project decision), not a spike.

## Concept Inventory (orchestrator only)

| Concept | Introduced by | Removed by | Status |
|---------|---------------|------------|--------|
| Feedback record schema | 8xb.t.k3v.1 | — | KEPT |
| Harness-class finding | 8xb.t.k3v.2 | — | KEPT |
| Comparative recommendation | 8xb.t.k3v.3 | — | KEPT |
| ADR-034 revision rules | 8xb.t.k3v.0 | — | KEPT |

## Out of Scope

- Implementation details: file structures, code organization, technology choices (decided at replan/work).
- Autonomous/RL proposer models; automated harness rewriting loops (paper itself cautions against unbounded sequences).
- Changes to agent runners or model providers; performance optimization beyond what comparison reporting needs.

## References

- [research-harness-learning-paper-and-gap-map.md](research-harness-learning-paper-and-gap-map.md) — paper analysis + ACE gap map (shared reference for all subtasks)
- Paper: https://arxiv.org/abs/2609.35738
- Related ADRs: 022 (config cascade), 025 (secrets threat model), 029 (`.ace-local` layout), 032 (e2e rerun/checkpoint gate)
