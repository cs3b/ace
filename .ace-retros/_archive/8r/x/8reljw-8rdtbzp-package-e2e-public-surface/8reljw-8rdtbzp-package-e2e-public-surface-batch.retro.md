---
id: 8reljw
title: 8rdtbzp-package-e2e-public-surface-batch
type: standard
tags: [e2e, assignment, review]
created_at: "2026-04-15 14:22:06"
status: active
---

# 8rdtbzp-package-e2e-public-surface-batch

## What Went Well

- The batch decomposition worked: 28 package slices could be driven one by one with clean subtree reports, clean worktrees, and explicit task completion checks after each forked child finished.
- The public-surface rewrite direction held across packages: command-first journeys, impact-first verifiers, and visible artifact checks transferred well from package to package without needing a different testing philosophy each time.
- Review cycles added real value instead of just cosmetic churn. The valid, fit, and shine passes each surfaced concrete issues that improved the final branch state before merge.
- Final closeout stayed disciplined once the tail steps were handled in order: full suite verification, release decisions, docs refresh, demo recording, PR description refresh, task archival, and batch retro creation all produced durable artifacts.

## What Could Be Improved

- The main orchestration mistake was conversational, not technical: after some forked child subtrees completed, the drive loop paused at progress-report boundaries instead of immediately resuming the parent queue. For this workflow that created unnecessary human prompting.
- Review-provider reliability remains uneven. Multiple review cycles saw Gemini capacity failures, and one shine cycle also showed a role-alias problem. The workflow still succeeded, but the signal quality depended heavily on Codex being available.
- Commit reorganization happened late, after the branch had already been pushed and reviewed. That forced a history rewrite, a force-push, and a second PR description pass. For large assignments, commit shaping should happen earlier or be planned as an explicit pre-review milestone.
- Demo closeout is still more manual than it should be. Picking a representative tape was easy here because stable package demos already existed, but the assignment had no single obvious "batch demo" artifact defined up front.

## Key Learnings

- Large E2E rewrites benefit from a fixed migration contract. The branch moved quickly because each package converged on the same public-surface structure: fewer hidden fixtures, more user-visible commands, and verifier contracts tied to final state instead of phrasing.
- Sequential fork execution is workable for long package batches, but only if the driver treats subtree completion as internal progress rather than a stop boundary. The workflow needs strict adherence to "poll, verify, resume parent, continue".
- Review Cycle Analysis:
  - The valid cycle found two real correctness/documentation issues, the fit cycle found two more environment/CLI contract issues, and the shine cycle found one high-priority regression plus one lower-priority optional item. Later cycles did catch qualitatively different issues instead of repeating the same concerns.
  - Across the reviewed cycles, every promoted high-priority finding led to a code or docs change. The low-priority shine item did not block completion, which suggests the severity calibration was mostly useful once provider noise was filtered out.
  - Provider failures were operational noise, not code findings. Capacity failures should be treated as review telemetry and fallback conditions, not as signals about branch quality.
- Post-review branch hygiene matters. Reorganizing the commit stack after the review cycles improved the final merge shape, but it also created extra push/PR-sync work. On future assignment batches, the branch should be normalized before the final review cycle when possible.

## Action Items

- Stop treating completed fork subtrees as user-facing pause points during `/as-assign-drive`; only stop on assignment completion or a real blocker.
- Continue using package-local retros and scoped commits for large batch migrations; that kept the branch auditable even after review fixes and commit reorganization.
- Start adding an explicit "representative demo target" decision near assignment creation for multi-package batches so the record-demo step does not require late selection.
- Start capturing review-provider failure rates as part of assignment retros so capacity and alias problems can be separated from actual review quality.

## Action Items
