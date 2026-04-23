---
id: 8rfedz
title: tmux-control-batch-closeout
type: standard
tags: [ace-tmux, ace-assign, ace-demo, review-cycles]
created_at: "2026-04-16 09:35:32"
status: active
---

# tmux-control-batch-closeout

## What Went Well
- The shared `ace-tmux` control surface gave `ace-assign` and `ace-demo` one reusable runtime contract instead of more tmux-specific one-off code paths.
- The assignment workflow recovered cleanly from the earlier PR-creation/auth issue and carried the remaining queue through two review cycles, releases, demo refresh, PR sync, and task archival without losing state.
- Review feedback produced useful follow-up fixes: detached-session fallback, VHS/backend rejection, unsupported `capture` removal, and recorder-side env forwarding all tightened the public contract before final merge.
- The final fork-provider demo remained a good acceptance check because it exercised the visible `work -> work-fs -> handoff` flow and verified the branch with real recorded artifacts.

## What Could Be Improved
- The Codex shell’s isolated `HOME` still caused operator-facing GitHub steps to fail until commands were re-run with `HOME=/home/mc`; this is survivable, but it is still an avoidable workflow tax for PR and release steps.
- The shine review preset currently references `review-geminie`, which fails immediately as an unknown role and wastes part of the review cycle.
- The review-driven contract cleanup happened in multiple small waves (`capture` docs removal, VHS rejection, env forwarding), which suggests the initial demo surface shipped a little too wide before the runtime/verification boundaries were locked.
- `ace-task update ... --move-to archive --gc` auto-archived the parent after the first child update. That behavior was correct, but the step instructions still read like three independent updates, which made the next two commands look like failures until the archive state was re-queried.

## Key Learnings
- Shared control surfaces only pay off when downstream consumers inherit the same execution context. `ace-demo` initially reused tmux control methods but not the recorder env, so the contract looked shared while behavior still diverged.
- Review-cycle fixes are faster when parser, runtime, docs, and tests are treated as one public-surface unit. The repeated `tmux capture` findings came from those layers drifting apart.
- Demo artifacts should be considered first-class branch outputs when they live under tracked docs paths. Recording succeeded technically, but the branch still needed an explicit commit/push step so the PR head matched the attached asset.

### Review Cycle Analysis
- The fit cycle produced 3 findings; 1 led to a real code change and 2 were stale by the time the review ran. That is a 66% false-positive/stale rate for that cycle’s synthesized output.
- The shine cycle produced 4 findings; 3 led to real changes and 1 was already fixed. That cycle was more useful, but it still depended on a single successful reviewer because the configured secondary role was misspelled.
- The fit cycle’s Gemini reviewer failed after ~226s due upstream `429 MODEL_CAPACITY_EXHAUSTED`, while the shine cycle’s secondary reviewer failed immediately because of the preset typo. In practice, Codex carried both cycles, so multi-model redundancy was weaker than it appeared on paper.
- The later shine cycle caught qualitatively different issues than the fit cycle: not structural capability gaps, but contract alignment problems between parser, runtime env propagation, and docs. That suggests the review staging itself is useful when the underlying reviewer configuration is healthy.

## Action Items
- Fix the `code-shine` review preset so it uses `review-gemini` instead of `review-geminie`.
- Tighten operator-facing workflow wrappers so GitHub/remote actions explicitly opt into the real operator auth context instead of depending on ambient `HOME` behavior from the agent shell.
- Add a pre-release/public-surface checklist for new demo directive features: parser accepts it, runtime implements it, backend limits are explicit, docs describe it, and tests cover the full contract.
- Clarify the task-archive workflow docs to note that `--gc` may archive the parent immediately once all subtasks are terminal, so follow-up verification should re-query the parent/task tree instead of repeating the same child mutation blindly.
