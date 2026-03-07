---
id: 8q6vcb
title: ace-compressor-nah-compact-mode-fidelity-and-refusal
type: standard
tags: [ace-compressor, compact-mode, fidelity, refusal]
created_at: "2026-03-07 20:53:42"
status: active
task_ref: 8q5.t.nah
---

# ace-compressor-nah-compact-mode-fidelity-and-refusal

## What Went Well
- Compact mode is now a real runnable path with deterministic `POLICY`, `FIDELITY`, `REFUSAL`, `GUIDANCE`, and `LOSS` records instead of a policy-only sketch.
- Narrative-heavy input such as `docs/vision.md` keeps the main thesis, problem inventory, principles, and example while still shrinking materially in compact mode.
- Safety behavior is explicit rather than silent. Rule-heavy input refuses with a clear retry path to `--mode exact` instead of pretending compression succeeded.

## What Could Be Improved
- `docs/decisions.md` feels broken from the outside even though the refusal is correct by design, because the UX still reads like a failed compression instead of an intentional safety gate.
- `docs/architecture.md` preserves its meaning well, but the compact output only trims bytes modestly, which means dense technical reference docs still need a stronger compaction story.
- Branch and task context are harder to follow than they should be because `_current` points at an archived task path, which made task-local storage and traceability confusing during review.

## Key Learnings
- Compact mode is currently a safe selective compressor, not a universal compressor for every document class in the repository.
- Refusal on rule-heavy sources is part of the product contract, not an implementation defect. The branch is optimizing for fidelity boundaries before maximum reduction.
- Narrative, mixed, and rule-heavy documents need different success expectations. One compression target is too coarse for all three classes.

## Action Items
- Document more clearly in `ace-compressor` usage that policy-heavy docs should fall back to `--mode exact`, and make that expectation visible before the refusal feels surprising.
- Tighten the acceptance story for dense technical narrative docs so compact mode either compresses them harder or states more plainly when only limited byte wins are expected.
- Fix or clarify branch-to-task pointers when archived tasks are reused as active branch context so follow-on workflows like retros stay easy to place and verify.
