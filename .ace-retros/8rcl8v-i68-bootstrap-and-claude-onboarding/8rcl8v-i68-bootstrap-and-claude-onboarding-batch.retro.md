---
id: 8rcl8v
title: i68-bootstrap-and-claude-onboarding-batch
type: standard
tags: [assignment, onboarding, review, release]
created_at: "2026-04-13 14:09:52"
status: active
---

# i68-bootstrap-and-claude-onboarding-batch

## What Went Well
- The batch produced concrete onboarding fixes across bootstrap, package wiring, and Claude CLI compatibility instead of addressing only one symptom. `ace-config init`, `ace-llm`, and `ace-llm-providers-cli` all ended the batch in a shippable state with releases and changelog coverage.
- The review cycles were useful and materially improved the branch. The valid cycle caught destructive `.gitignore` overwrite risk and repo-root path anchoring, the fit cycle removed unnecessary Claude capability probes, and the shine cycle found the missing `CLAUDECODE` env parity plus the line-aware `.gitignore` follow-up.
- Focused regression tests were added each time behavior changed, which kept the follow-up fixes fast to verify and made the later review findings straightforward to apply.
- The final closeout quality improved once the driver stayed inside the assignment loop: PR updates, releases, demo recording, commit reorganization, and task archival all completed in one pass.

## What Could Be Improved
- The driver initially stopped after subtree progress instead of checking pinned assignment status. That was an execution failure, not a repo blocker, and it cost an extra recovery cycle.
- Dirty-tree handling around generated `.ace/...` files was too blunt. Generated config scaffolding should have been classified and cleaned immediately instead of being treated as a reason to pause execution.
- Release-step verification needs a stricter post-commit check. I incorrectly reported that `Gemfile.lock` had not changed during one review-cycle release, and only the next step surfaced the missing lockfile commit.
- The shine review exposed a configuration defect outside product code: the workflow asked for `review-geminie`, which is not a defined role. Review-cycle infra defects like that should be treated as first-class workflow issues and fixed promptly.
- Task archival commands can race with path movement when `--move-to archive --gc` is run repeatedly against refs that have already been relocated. The workflow should prefer state verification after the first successful archival mutation instead of replaying the whole loop blindly.

## Key Learnings
- Review-cycle analysis:
  - The valid cycle (`review-8rckmg`) produced four findings, three of which led to code changes. The only invalid item was a false positive about Ruby bare `rescue`, so the false-positive rate there was low and the cycle had strong signal.
  - The fit cycle (`review-8rcku4`) produced two findings and both led to code changes. That cycle caught performance and test-isolation regressions that were qualitatively different from the earlier correctness issues.
  - The shine cycle (`review-8rcl0p`) also produced two code-changing findings, but only one reviewer ran because `review-geminie` is misconfigured. Even with partial review coverage, the cycle still found a real nested-session bug and a maintainability issue in `.gitignore` handling.
- The recurring pattern across review cycles was “feature fix lands, then edge-condition hardening follows.” The fixes were correct in direction, but they benefited from additional pressure on repeat runs, nested environments, and existing-user state rather than greenfield cases.
- Assignment automation needs explicit state gates at every lifecycle boundary: after subtree completion, after release commits, after task archival, and before final response. Most execution mistakes in this batch were orchestration mistakes rather than code mistakes.

## Action Items
- Update `assign/drive` and related integration skills to keep the pinned assignment status as the only completion signal and to classify generated dirty-tree side effects before deciding to stop, clean, or commit.
- Tighten release-step reporting so `git status --short` is checked after every release commit set and before the step report is finalized, with special attention to delayed `Gemfile.lock` updates after `bundle install`.
- Fix the shine review preset/provider mapping so it uses the real `review-gemini` role name instead of `review-geminie`.
- Improve the task-archive workflow to detect when refs have already moved to `_archive` and switch to verification mode instead of retrying updates against stale paths.
- Keep recording targeted demo tapes for onboarding-sensitive fixes; the bootstrap tape created here made the final PR easier to verify than prose alone.
