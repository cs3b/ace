---
id: 8wmvwb
title: hitl-task-batch-skipped-commit-and-external-review
type: standard
tags: [hitl, process, review, git]
created_at: "2026-09-23 21:15:55"
status: active
---

# hitl-task-batch-skipped-commit-and-external-review

Date: 2026-09-23
Context: Architect session — creation of the HITL task batch A1–A5
(8wm.t.vrz/vs0/vs1/vs2/vs3) from the Captain's dictated architecture plan.
Author: architect agent (pi)
Type: Standard

## What Went Well

- All 5 tasks minted in the dictated order with B36TS IDs and the dictation
  preserved verbatim as task bodies (acceptance criteria included for A1,
  folder contract for A3).
- Dependency graph encoded directly in frontmatter
  (`A1 -> (A2 ∥ A3) -> A4 -> A5`), so execution order survives without
  side-channel notes.
- `ace-task doctor` run after creation; confirmed none of the new tasks
  introduced issues (all reported errors were pre-existing).

## What Could Be Improved

- **Batch declared done while uncommitted.** The 5 task files existed only on
  disk; nothing was preserved in git history and nothing was available for the
  lab admin to push to main. The work was one `git clean` away from being lost.
- **No external review of the batch.** The architect role mandates that every
  task goes through the full pipeline (spec by builder, code by builder,
  review with executed checks), yet the task definitions themselves — the
  input to that whole pipeline — were never reviewed by an external agent
  before being presented as final.
- Minor: initial instruction referenced a non-existent skill
  (`/as-review-create`); the correct capture path was `as-retro-create`.
  Skill names must be verified against the available list before routing.
- Environmental: `ace-git-commit` LLM message generation failed (all providers
  401/expired); the `--only-staged --no-split -m` fallback worked and was used.

## Key Learnings

- "Created" is not "delivered". A task batch is done only when its artifacts
  are committed; pushing to main stays with the lab admin, but committing is
  the creator's job and belongs to the definition of done.
- Review is not only for builder output. Delegation artifacts (task briefs,
  specs, dependency graphs) are upstream of the entire pipeline — an error
  there multiplies across A1–A5. They need the same external review gate.
- Fallback paths matter: when LLM commit-message generation is unavailable,
  `ace-git-commit --only-staged --no-split -m "..."` completes the job.

## Action Items

### Stop doing

- Presenting an artifact batch as complete in the same turn it was created,
  without committing it.
- Treating "review" as a downstream-only concern that never applies to the
  architect's own outputs.

### Continue doing

- Minting task IDs in dictated order and encoding the dependency graph in
  frontmatter.
- Verifying new artifacts with `ace-task doctor` before hand-off.

### Start doing

- End every `ace-task create` batch with an immediate
  `ace-git-commit .ace-tasks/` in the same session; state explicitly that
  push to main is the lab admin's step.
- Route dictated task briefs through an external reviewer
  (as-review-run / reviewer agent) before declaring the batch ready, mirroring
  the executed-checks review the pipeline applies to code.
