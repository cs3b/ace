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

## Execution boundary

The ordinary commands below use the local campaign store and coordinator-accepted
ordinary receipts. For an installed protected parent with registered
`review_campaign`, use its original authenticated authority and the protected
handoff below instead. The installed launcher owns the original linked collection,
check and approval children; each must succeed, settle and release before its
receipt can count. A worker-local report or ordinary `attempt finish` cannot
replace that linkage. Draft creation/update may precede review; ready and merge
still require the accepted current-candidate result and executed checks.

## 1. Choose and prepare the scope

Identify the PR from an explicit number, owner/repository#number or URL and read normalized evidence with `ace-git pr show IDENTIFIER --format json`. Use the assignment's retained forge selection: `--server NAME` or `--default-server`, mutually exclusive; otherwise resolve the repository remote. Keep that same selection on `ace-review --pr IDENTIFIER` in every round. Do not infer a forge or PR from a fixed hostname or caller identity. Read its goal, current requirements, relevant ADRs and changed-file list. Use the smallest set of presets covering the change. Small coherent PRs can be reviewed whole; split large inputs by high-level module or functional lens, not arbitrary file chunks. Include needed contracts and code when reviewing tests and include integration behavior when modules interact.

Use `ace-review --pr IDENTIFIER --server NAME --preset PRESET --dry-run` (or the retained default/remote selection) to inspect the selected/omitted files, complete prompt and budget. Context and instructions each have a 30k ceiling; total input has a 128k ceiling. Change scope if too large; do not silently truncate or claim omitted code was reviewed. Generated files may use an appropriate deterministic check, recorded in the round summary, without a separate certification system.

For presets with a goals brief, `--prepare-goals-brief` generates or reuses the shared summary. Its cache follows source content and instructions, not review-round state. Architectural foundations should receive design review before implementation.

## 2. Run a round and verify findings

Run `ace-review --pr IDENTIFIER --server NAME --preset PRESET --auto-execute` with the retained default/remote selection when applicable. Pass selected previous sessions with `--evidence-session <path>` when useful. Earlier commit SHAs are expected: prior reports provide context and dispositions, not current-code certificates. Supply a short summary of fixes and outstanding issues through the preset context when it is more useful than full reports. Every final accepted review and test receipt must bind the current candidate SHA; journal commits are separate from candidate_head. A committed task edit changes the candidate and requires renewed evidence. CI remains visible and advisory; failed execution, unresolved findings or stale receipts block acceptance.

Round N+1 does not need to re-review unchanged code. `--delta` scopes the round to the diff since the reference head recorded by the most recent prior session of that PR (`--delta <head>` names an explicit reference), carries its findings forward as evidence, and completes as a zero-model no-op session when the delta is empty. When the project config declares `exempt_paths` and a delta touches only those paths, the round is recorded as a review-exempt no-op; mixed deltas review only the non-exempt part. Full rounds are never converted into no-ops by exempt paths.

First-round review looks for concrete defects against the agreed requirements. Subsequent rounds check fixes, regressions, unresolved issues and the integration affected by changes. They may report newly evidenced defects, but should not redesign the solution or reopen a closed finding without new evidence.

Verify reports against code and requirements. Use `ace-review-feedback list --session <path>`, `show`, `verify` and `resolve` to preserve findings and dispositions. Distinguish defects, architectural decisions and optional improvements. A single reviewer's valid finding matters; do not discard it for lack of consensus. Severity is verified by the agent, not accepted just because the model assigned it.

Fix confirmed P0/P1 and run appropriate tests. Verify P2 and lower findings, fix those within the task or defer with rationale; they do not independently require another round. Do not expand the PR to implement speculative improvements. If the same blocker recurs without an effective fix, diagnose the cause or request the needed product/architecture decision instead of repeating the same review.

## 3. Ordinary campaign recording and finish

Use the durable `ace-review campaign` authority for completed rounds, verified dispositions, required scopes and clean streak. Start/reuse it with explicit subject JSON and a frozen behavioral requirements document; snapshot the applicable delivery policy. Pin an empty round before collection with head/base, scope IDs and presets, then pass `--campaign ID --campaign-round ROUND --campaign-scope SCOPE` to the existing review runner. Have the existing assignment coordinator accept each completed collection as a `review-collect` receipt with a passed review-execution outcome and checksummed metadata/report/prompt artifacts. Include its accepted receipt reference with the session and verified feedback dispositions in `campaign record-round`; editable execution flags alone cannot count. Full PR scopes require the complete unfiltered whole-PR inventory without delta references. Filtered module reviews and delta reviews use explicit module or delta scopes frozen in the campaign policy; pin the delta reference before collection. The default delivery `full` policy requires whole-PR rounds. Record partial attempts without counting them as completed rounds. See `ace-review/docs/campaigns.md` for exact input schemas and examples.

Resume with `campaign status ID --format json` after a restart or context compaction. Changed requirements create a linked successor with a reason and retained findings; implementation commits, task lifecycle metadata and completion reports do not change the frozen requirements document. Commits, squash and rebase preserve the total and clean counters. Current evidence validity is separate: changed head/base or missing/corrupt source artifacts block acceptance without erasing historical rounds. Use a new evidenced occurrence to reopen a canonical finding instead of transitioning terminal feedback files back to pending. Later High/Critical assessments, including terminal corrections to earlier findings, require a completed current round before an earlier approval can become acceptable; an empty or partial disposition submission cannot clear that gate.

Examples:

- P1 → clean → clean: finish after round 3.
- clean → clean → clean: finish after round 3.
- P1 → clean → P1 → clean → clean: finish after round 5.
- An incomplete attempt does not increment either counter and cannot hide an outstanding blocker.
- A round that finds a confirmed P1 is not clean even if it is fixed immediately afterward.

After the completion rule is met and changes have appropriate test results, update the PR description with actual reviewers, scopes, fixes, deferred findings and limitations, then mark the draft ready. Finish with `ace-review campaign finish ID --format json` after the final round records independent current-head approval backed by an accepted ordinary review receipt and passing required check artifacts. The source approval receipt must bind the approved reviewer verdict, actors, head and report hashes; caller-written approval JSON and collection receipts alone cannot approve the candidate. Search convergence alone cannot approve stale/incomplete evidence or unresolved earlier P0/P1. The result remains a local artifact until ace-assign independently verifies it through its existing attempt receipt boundary. Keep formal merge checks at merge time. Do not merge without explicit user authorization, post replies to people or resolve their threads without authorization. Do not make optional code changes after completion that would unnecessarily reopen review.


## Protected campaign recording and parent result handoff

Use the original parent mapping, assignment, attempt, exact candidate SHA and
positive candidate generation from its accepted registration/status. Campaign ID,
subject, frozen requirements identity and policy come from that registered parent;
these commands have no caller-selected campaign, project, scope or base flags.
The round's base and scopes remain the exact pinned R1 input. Do not run local
`ace-review campaign record-round` or `finish` as an installed authority substitute.

Upload the existing R1 round JSON inside the closed R2 envelope:
`{"version":1,"round":ROUND_OBJECT,"artifacts":[{"path":"report.md","sha256":"SHA256"}]}`.
`ROUND_OBJECT` retains the documented attempt_id, round_id, head/base,
required_scopes, scope_identity, sessions, dispositions and optional approval.
Its attempt_id equals the stable mutation ID below and its head equals the parent
SHA. Each artifact path is a bounded relative materialization name; it is not an
instruction for the authority to read the worker filesystem. Supply exact report,
metadata, prompt, feedback and approval bytes referenced by that round as ordered
`--artifact` files matching the envelope's paths/digests. The envelope is at most
16 KiB, with at most 16 artifacts of at most 64 KiB each. The authority privately
materializes bytes and resolves child receipt references from canonical history;
collection proves execution, while independently accepted approval and matching
check children establish acceptance. Never add the parent campaign result to a
source child receipt.

```sh
ace-assign campaign-record-round --mapping MAPPING --assignment PARENT --attempt ATTEMPT --head SHA --candidate-generation N --mutation ROUND-ATTEMPT --input ROUND-ENVELOPE.json --artifact REPORT-BYTES
ace-assign campaign-export-result --mapping MAPPING --assignment PARENT --attempt ATTEMPT --head SHA --candidate-generation N --output RESULT.json
```

Repeat `--artifact` for all envelope artifacts in declared order, or omit it for
an empty pin. Record each completed round under the frozen policy; export succeeds
only when that policy, current candidate, independent approval and required checks
are accepted. Export creates mode0600 result bytes once and reports path, sha256,
result_identity and journal_commit. An existing output is reusable only when its
bytes match exactly; do not rewrite or compose a replacement result.

The original parent receipt keeps its existing assignment/attempt/project/scope,
producer, exact head, `operation: "review"`, `verdict: "succeeded"`, independent
reviewer approval and executed checks. Add
`"campaign":{"id":"REGISTERED-CAMPAIGN","result":{"path":"RESULT.json","sha256":"EXPORTED-SHA256"}}`
and include that identical reference in its `artifacts` array. Supply the exact
exported bytes in the matching ordered upload slot alongside the receipt's other
artifacts; local artifact names become canonical imported references on acceptance.
Submit through the maintained public boundary, using the persisted authority
generation and a stable original result mutation:

```sh
ace-assign submit-result --mapping MAPPING --assignment PARENT --attempt ATTEMPT --head SHA --candidate-generation N --expected-generation G --mutation RESULT-MUTATION --receipt PARENT-RECEIPT.json --artifact RESULT.json
```

This submits evidence; it does not independently approve, finish or release the
parent. The original reviewer/finish owner retains that gate. Authority generation
G and candidate generation N are distinct. Ready/merge revalidate this canonical
parent campaign result and checks at the current candidate.

On a lost reply/restart, preserve the exact round mutation, envelope and ordered
bytes; identical round replay returns retained history without another completed
round. Re-export may only reuse identical result bytes. Preserve original result
mutation, generation and upload bytes for result replay; do not refresh selectors
to manufacture success. Changed candidate, policy, requirements or missing child
settlement/source artifacts refuses current export/submission/ready/merge while
retaining historical rounds. Read original canonical status and route the precise
producer blocker; do not fabricate receipts or bypass to ordinary commands.
