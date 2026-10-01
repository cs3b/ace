---
doc-type: workflow
title: Review PR in converging rounds
purpose: Review a PR, verify concrete findings and finish after two clean rounds
ace-docs:
  last-updated: 2026-09-24
  last-checked: 2026-09-24
---

# Review PR

## Goal and completion rule

The agent runs this workflow; ACE executes individual reviews. Complete at least **3 rounds for the PR**, with the **last 2 consecutive rounds free of confirmed P0/P1 (Critical/High)**. An unresolved earlier P0/P1 remains blocking even if another reviewer does not mention it. A confirmed P0/P1 resets the clean-round streak. There is no additional final review after this rule is satisfied.

One round covers the PR's needed scope, including cross-module integration. A large round can use several coherent module sessions; modules do not have separate round counters. A round counts only after the needed reports have completed and the agent has verified their findings. Failed providers and incomplete reports do not count as clean rounds.

Use at least one available reviewer per needed scope. Prefer the project's configured models, but preferences are not an allowlist. Honor the user's current provider/model restrictions. Record actual provider, model, reasoning and completion status. A zero process exit code alone is not a completed review.

## 1. Choose and prepare the scope

Identify the PR from the argument or `gh pr view`. Read its goal, current requirements, relevant ADRs and changed-file list. Use the smallest set of presets covering the change. Small coherent PRs can be reviewed whole; split large inputs by high-level module or functional lens, not arbitrary file chunks. Include needed contracts and code when reviewing tests and include integration behavior when modules interact.

Use `ace-review --pr <number> --preset <preset> --dry-run` to inspect the selected/omitted files, complete prompt and budget. Context and instructions each have a 30k ceiling; total input has a 128k ceiling. Change scope if too large; do not silently truncate or claim omitted code was reviewed. Generated files may use an appropriate deterministic check, recorded in the round summary, without a separate certification system.

For presets with a goals brief, `--prepare-goals-brief` generates or reuses the shared summary. Its cache follows source content and instructions, not review-round state. Architectural foundations should receive design review before implementation.

## 2. Run a round and verify findings

Run `ace-review --pr <number> --preset <preset> --auto-execute` for the needed scopes. Pass selected previous sessions with `--evidence-session <path>` when useful. Earlier commit SHAs are expected: prior reports provide context and dispositions, not current-code certificates. Supply a short summary of fixes and outstanding issues through the preset context when it is more useful than full reports.

Round N+1 does not need to re-review unchanged code. `--delta` scopes the round to the diff since the reference head recorded by the most recent prior session of that PR (`--delta <head>` names an explicit reference), carries its findings forward as evidence, and completes as a zero-model no-op session when the delta is empty. When the project config declares `exempt_paths` and a delta touches only those paths, the round is recorded as a review-exempt no-op; mixed deltas review only the non-exempt part. Full rounds are never converted into no-ops by exempt paths.

First-round review looks for concrete defects against the agreed requirements. Subsequent rounds check fixes, regressions, unresolved issues and the integration affected by changes. They may report newly evidenced defects, but should not redesign the solution or reopen a closed finding without new evidence.

Verify reports against code and requirements. Use `ace-review-feedback list --session <path>`, `show`, `verify` and `resolve` to preserve findings and dispositions. Distinguish defects, architectural decisions and optional improvements. A single reviewer's valid finding matters; do not discard it for lack of consensus. Severity is verified by the agent, not accepted just because the model assigned it.

Fix confirmed P0/P1 and run appropriate tests. Verify P2 and lower findings, fix those within the task or defer with rationale; they do not independently require another round. Do not expand the PR to implement speculative improvements. If the same blocker recurs without an effective fix, diagnose the cause or request the needed product/architecture decision instead of repeating the same review.

## 3. Record progress and finish

Use the durable `ace-review campaign` authority for completed rounds, verified dispositions, required scopes and clean streak. Start/reuse it with explicit subject JSON and a frozen behavioral requirements document; snapshot the applicable delivery policy. Pin an empty round before collection with head/base, scope IDs and presets, then pass `--campaign ID --campaign-round ROUND --campaign-scope SCOPE` to the existing review runner. Have the existing assignment coordinator accept each completed collection as a `review-collect` receipt with a passed review-execution outcome and checksummed metadata/report/prompt artifacts. Include its accepted receipt reference with the session and verified feedback dispositions in `campaign record-round`; editable execution flags alone cannot count. Full PR scopes require the complete unfiltered whole-PR inventory without delta references. Filtered module reviews and delta reviews use explicit module or delta scopes frozen in the campaign policy; pin the delta reference before collection. The default delivery `full` policy requires whole-PR rounds. Record partial attempts without counting them as completed rounds. See `ace-review/docs/campaigns.md` for exact input schemas and examples.

Resume with `campaign status ID --format json` after a restart or context compaction. Changed requirements create a linked successor with a reason and retained findings; implementation commits, task lifecycle metadata and completion reports do not change the frozen requirements document. Commits, squash and rebase preserve the total and clean counters. Current evidence validity is separate: changed head/base or missing/corrupt source artifacts block acceptance without erasing historical rounds. Use a new evidenced occurrence to reopen a canonical finding instead of transitioning terminal feedback files back to pending. Later High/Critical assessments, including terminal corrections to earlier findings, require a completed current round before an earlier approval can become acceptable; an empty or partial disposition submission cannot clear that gate.

Examples:

- P1 → clean → clean: finish after round 3.
- clean → clean → clean: finish after round 3.
- P1 → clean → P1 → clean → clean: finish after round 5.
- An incomplete attempt does not increment either counter and cannot hide an outstanding blocker.
- A round that finds a confirmed P1 is not clean even if it is fixed immediately afterward.

After the completion rule is met and changes have appropriate test results, update the PR description with actual reviewers, scopes, fixes, deferred findings and limitations, then mark the draft ready. Finish with `ace-review campaign finish ID --format json` after the final round records independent current-head approval and passing required check artifacts. Search convergence alone cannot approve stale/incomplete evidence or unresolved earlier P0/P1. The result remains a local artifact until ace-assign independently verifies it through its existing attempt receipt boundary. Keep formal merge checks at merge time. Do not merge without explicit user authorization, post replies to people or resolve their threads without authorization. Do not make optional code changes after completion that would unnecessarily reopen review.
