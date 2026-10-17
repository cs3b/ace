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

Identify the PR from an explicit number, owner/repository#number or URL and read normalized evidence with `ace-git pr show IDENTIFIER --format json`. Use the assignment's retained forge selection: `--server NAME` or `--default-server`, mutually exclusive; otherwise resolve the repository remote. Keep that same selection on `ace-review --pr IDENTIFIER` in every round. Do not infer a forge or PR from a fixed hostname or caller identity. Read its goal, current requirements, relevant ADRs and changed-file list. Use the smallest set of presets covering the change. Small coherent PRs can be reviewed whole; split large inputs by high-level module or functional lens, not arbitrary file chunks. Include needed contracts and code when reviewing tests and include integration behavior when modules interact.

Use `ace-review --pr IDENTIFIER --server NAME --preset PRESET --dry-run` (or the retained default/remote selection) to inspect the selected/omitted files, complete prompt and budget. Context and instructions each have a 30k ceiling; total input has a 128k ceiling. Change scope if too large; do not silently truncate or claim omitted code was reviewed. Generated files may use an appropriate deterministic check, recorded in the round summary, without a separate certification system.

For presets with a goals brief, `--prepare-goals-brief` generates or reuses the shared summary. Its cache follows source content and instructions, not review-round state. Architectural foundations should receive design review before implementation.

## 2. Run a round and verify findings

Run `ace-review --pr IDENTIFIER --server NAME --preset PRESET --auto-execute` with the retained default/remote selection when applicable. Pass selected previous sessions with `--evidence-session <path>` when useful. Earlier commit SHAs are expected: prior reports provide context and dispositions, not current-code certificates. Supply a short summary of fixes and outstanding issues through the preset context when it is more useful than full reports. Every final accepted review and test evidence must bind the current candidate SHA; commits do not reset the round counters. A committed task edit changes the candidate and requires renewed evidence. CI remains visible and advisory; failed execution, unresolved findings or stale receipts block acceptance.

Round N+1 does not need to re-review unchanged code. `--delta` scopes the round to the diff since the reference head recorded by the most recent prior session of that PR (`--delta <head>` names an explicit reference), carries its findings forward as evidence, and completes as a zero-model no-op session when the delta is empty. When the project config declares `exempt_paths` and a delta touches only those paths, the round is recorded as a review-exempt no-op; mixed deltas review only the non-exempt part. Full rounds are never converted into no-ops by exempt paths.

First-round review looks for concrete defects against the agreed requirements. Subsequent rounds check fixes, regressions, unresolved issues and the integration affected by changes. They may report newly evidenced defects, but should not redesign the solution or reopen a closed finding without new evidence.

Verify reports against code and requirements. Use `ace-review-feedback list --session <path>`, `show`, `verify` and `resolve` to preserve findings and dispositions. Distinguish defects, architectural decisions and optional improvements. A single reviewer's valid finding matters; do not discard it for lack of consensus. Severity is verified by the agent, not accepted just because the model assigned it.

Fix confirmed P0/P1 and run appropriate tests. Verify P2 and lower findings, fix those within the task or defer with rationale; they do not independently require another round. Do not expand the PR to implement speculative improvements. If the same blocker recurs without an effective fix, diagnose the cause or request the needed product/architecture decision instead of repeating the same review.

## 3. Record rounds locally and finish

Keep round state locally: each `ace-review --pr` run produces a review session and `ace-review-feedback` records verified findings and dispositions. Do not require a durable campaign or a coordinator-accepted journal receipt; those belonged to the removed lab authority model. The agent keeps the total round count and the clean-round streak across restarts and context compaction, and records them in the PR description or an assignment report when useful. A round counts only after the needed session reports completed and the agent verified their findings; failed providers and incomplete reports do not count.

Resume after a restart from the PR's review sessions and the current head. Changed requirements or a moved head do not erase historical rounds, but current-head evidence must be renewed. Use a new evidenced occurrence to reopen a finding; do not transition terminal feedback files back to pending. Later High/Critical assessments, including terminal corrections to earlier findings, require a completed current round before an earlier approval can become acceptable; an empty or partial disposition submission cannot clear that gate.

Examples:

- P1 -> clean -> clean: finish after round 3.
- clean -> clean -> clean: finish after round 3.
- P1 -> clean -> P1 -> clean -> clean: finish after round 5.
- An incomplete attempt does not increment either counter and cannot hide an outstanding blocker.
- A round that finds a confirmed P1 is not clean even if it is fixed immediately afterward.

After the completion rule is met and changes have appropriate test results, update the PR description with actual reviewers, scopes, fixes, deferred findings and limitations, then mark the draft ready with the local forge command (`ace-git pr ready`). Search convergence alone cannot approve stale/incomplete evidence or unresolved earlier P0/P1. Keep formal merge checks at merge time. Do not merge without explicit user authorization, post replies to people or resolve their threads without authorization. Do not make optional code changes after completion that would unnecessarily reopen review.

## Role workflow (planned L5.5)

The coworker/reviewer role workflow that connects these review rounds to the new
role handoff lands in L5.5. Until then, use the local review rounds above and
keep the reviewer independent from the worker.
