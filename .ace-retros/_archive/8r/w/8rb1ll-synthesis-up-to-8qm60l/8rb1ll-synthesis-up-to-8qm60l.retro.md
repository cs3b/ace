---
id: 8rb1ll
title: synthesis-up-to-8qm60l
type: standard
tags: [synthesis]
created_at: "2026-04-12 01:03:59"
status: active
---

# synthesis-up-to-8qm60l

## What Went Well

- Fork/subtree orchestration repeatedly delivered end-to-end execution when recovery rules were followed (7/9: 8qlrl3, 8qlse8, 8qlsmt, 8qlu63, 8qlvhx, 8qm0nn, 8qm60l).
- Review and verification loops caught real issues with high signal, including config regressions and architectural drift (4/9: 8qlrl3, 8qlvhx, 8qlu63, 8qm60l).
- Commit discipline around scoped changes improved traceability, rollback safety, and release sequencing (4/9: 8qlu63, 8qlvhx, 8qm0nn, 8qm60l).
- Documentation refresh and guide-template improvements were effective once examples and explicit constraints were added (3/9: 8qlu63, 8qm4nu, 8qm60l).

## What Could Be Improved

- Fork execution context remains fragile when provider/config state is missing or mutated (`@yolo` loss, provider outages, missing session metadata), causing retry loops and stalled review steps (6/9: 8qlrl3, 8qlse8, 8qlvhx, 8qm0nn, 8qm4nu, 8qm60l).
- Recovery instructions must stay explicit and path-based; semantic references and compressed continue-work guidance create avoidable ambiguity (3/9: 8qlse8, 8qlsmt, 8qlrl3).
- Workflow/catalog consistency gaps still surface (missing workflow links, heavy gates for doc-only work, release naming mismatches), increasing execution friction (4/9: 8qlse8, 8qlrl3, 8qlu63, 8qm60l).
- Some retros lacked substantive content, reducing synthesis value and traceability (1/9: 8qlsgf).

## Key Learnings

- Fork reliability requires explicit pre-fork invariants: stable provider config, clean-tree checks, and deterministic context handoff.
- Recovery quality depends on exact artifacts, not inferred intent: list concrete report paths and reuse failed-step instruction bodies verbatim.
- Multi-cycle review is most valuable when findings are convergent and actionable; polish cycles should be skipped once correctness is saturated.
- Lightweight quality gates should be selected by change type (docs-only vs code) to avoid expensive low-yield loops.

## Action Items

- Stop:
  - Allowing fork/review agents to modify orchestration config files (especially `.ace/assign/config.yml`) as a side effect of unrelated work.
  - Using vague recovery instructions that omit explicit file paths and full execution context.
- Continue:
  - Delegating fork subtrees with guard review of reports plus post-run clean-tree verification.
  - Using scoped commits and immediate release/changelog synchronization within subtree execution.
  - Running multi-model review cycles until major correctness issues converge, then applying a circuit breaker for low-value polish cycles.
- Start:
  - Add enforced pre-fork provider/session validation (including `@yolo` and metadata presence) before every `fork-run`.
  - Audit assignment catalog/workflow entries for missing `workflow:` mappings and gate mismatches (for example doc-only E2E overreach).
  - Add a minimal quality standard for retros so empty retros are flagged for follow-up before synthesis batches.

## Source Retros

- 8qlrl3
- 8qlse8
- 8qlsgf
- 8qlsmt
- 8qlu63
- 8qlvhx
- 8qm0nn
- 8qm4nu
- 8qm60l
