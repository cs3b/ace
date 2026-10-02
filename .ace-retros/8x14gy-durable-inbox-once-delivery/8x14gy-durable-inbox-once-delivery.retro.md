---
id: 8x14gy
title: durable-inbox-once-delivery
type: standard
tags: [ace-herdr, inbox, review]
created_at: "2026-10-02 02:58:50"
status: active
---

# Durable inbox once delivery (task 8wm.t.y23)

## What Went Well

- Reusing `DeliveryRecordStore` and its per-event lock gave the inbox durable write-ahead state without a second idempotency store. An accepted native submission is saved before an optional idle wake, and uncertain outcomes require signed operator or supervisor proof.
- Exact-session Codex and Pi queues prevent a reused pane from receiving the payload. Installed TS-HERDR-001 passed all three goals, including separate CLI processes, signed reconciliation, and idle Pi delivery.
- Focused unit cases caught crash/retry, target movement, malformed replacement addresses, and bounded wake process behavior. The final package run passed 297 tests and 897 assertions; `ace-herdr v0.2.0` was prepared locally.

## What Could Be Improved

- Fork execution hit Codex CLI deadlines twice, requiring recovery children and preserving two uncertain local-only attempts. Smaller execution boundaries or a longer supported fork deadline would reduce recovery overhead.
- The pre-commit review fallback began with lint and missed substantive routing risks. Independent code review found the issues before release, but it should run earlier in the implementation loop.
- `ace-bundle project` stalled in its compressor subprocess during release preparation. The earlier onboarding bundle and direct release checks allowed progress, but the compressor needs a bounded failure path.

## Key Learnings

- A signed supersession outcome proves what happened to the old submission; it does not authorize an implicit new recipient. Replacement session and pane identity must be explicit in the signed receipt and verified live before another claim.
- Native acceptance and pane wake are separate effects. Persist acceptance first. The wake carries no payload, has a subprocess deadline, drains output with bounded memory, and retains structured errors for recovery.
- Process timeouts must be enforced at the child boundary. Wrapping `Open3.capture3` in `Timeout.timeout` can still wait during cleanup; `Open3.popen3` with process-group termination and bounded draining gives a real deadline.

### Review Cycle Analysis

- The Codex `code-valid` reviewer completed seven rounds on the full change and follow-up diffs. It raised 12 distinct findings across the first six rounds; all 12 were verified and fixed. The seventh round found zero issues at the implementation head. A separate release-diff review found zero issues.
- Findings progressed from payload routing risks to subprocess edge cases. Keeping exact-head review and test evidence exposed regressions introduced by earlier fixes. The configured Gemini reviewer could not run because its CLI was unavailable; Codex completed every required scope.

## Action Items

- Start independent correctness review after the first working inbox slice, before broad E2E and release work.
- Add a bounded compressor subprocess failure path to `ace-bundle project` so release preparation cannot wait indefinitely.
- Preserve the installed Codex/Pi scenario as a release gate for future inbox transport changes.
