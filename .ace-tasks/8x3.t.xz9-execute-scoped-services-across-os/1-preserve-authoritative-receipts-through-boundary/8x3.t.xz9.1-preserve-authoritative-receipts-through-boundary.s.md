---
id: 8x3.t.xz9.1
status: in-progress
priority: high
created_at: "2026-10-04 23:30:10"
estimate: medium
dependencies: [8x3.t.xz9.0]
tags: []
parent: 8x3.t.xz9
needs_review: false
title: Preserve authoritative receipts through boundary failures
bundle:
  presets: [project]
  files: [.ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/8x3.t.xz9-execute-scoped-services-across-os-users-with.s.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/ux/usage.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/receiver-boundary-research.md, ace-lab/lib/ace/lab/organisms/service_request_service.rb, ace-lab/lib/ace/lab/molecules/service_executor.rb, ace-assign/lib/ace/assign/organisms/attempt_coordinator.rb, ace-assign/lib/ace/assign/molecules/evidence_journal.rb, ace-hitl/lib/ace/hitl/lifecycle/service.rb, ace-hitl/lib/ace/hitl/lifecycle/peer.rb, ace-herdr/lib/ace/herdr/molecules/bounded_process.rb, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/protected-authority-contract.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/test-plan.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/1-preserve-authoritative-receipts-through-boundary/ux/usage.md]
  commands: []
---

# Preserve authoritative receipts through boundary failures

## User experience and expected behavior

Input: authenticated IDs and existing structured service/inbox input through the deployment map. Process: An accepted protected service remains attributable through contention, restart and ambiguous external outcome without duplicate dispatch or orphan writers.
Output: existing sanitized public outcome and a protected verifiable evidence reference; uncertainty is explicit.

## Interface contract

Reuse the first slice public APIs. No new journal or compatibility protocol. Preserve terminal replay visibility and no-effect settlement contracts.

## Scope and defaults

This child is a real end-to-end slice, advisory size medium. It includes the integration required for its observable result. Fixed deployment-selected identities/configuration; no caller-selected path, key, executable or asserted outcome. Operate through public ACE APIs with a read-only preview/status where applicable. No force bypass; verbose/quiet change presentation only, never authority. Empty/unknown IDs, malformed payload and unavailable authority refuse. Credentials and message bodies stay out of public output and retained observation artifacts. Installation/domain operation acceptance remains lab-config; R2/R3 remain downstream. No implementation in this drafting pass.

## Success criteria

- [ ] SC1: Concurrent identical requests execute once; conflicting reuse refuses.
- [ ] SC2: Loss after claim/effect and receiver/authority restart retain uncertainty until attributable evidence; no blind replay.
- [ ] SC3: Second listener preserves active endpoint; stuck/noisy handler descendants are killed and reaped within bounds.

## Verification plan

Unit checks cover exact immutable binding, peer-role allowlist, bounded schema and error classification. Integration uses real temporary protected files/socket and canonical journal/event locking; do not mock ownership or replace the system under test. Installed E2E uses actual distinct OS users and genuine provider runtime where required.

- Race duplicate requests and terminalization with claim; crash after claim, after effect and before/after durable completion; inspect one protected journal chain.
- Real descendant attempts delayed write after timeout; verify no write and no live descendant; stale/active socket contention verifies inode/lock ownership.

Run source `bin/ace-test` for affected package/layer and `bin/ace-test-suite` default fast verification after implementation, plus recorded installed native/multi-user acceptance from the family test plan. Unit fixtures are sanitized protocol examples sourced from the genuine drill; fabricated examples cannot satisfy positive native criteria.

## Readiness questions

Independent readiness review APPROVED this scope at 0626be045; see ../readiness-review-2026-10-05.md. Promoted to pending; implementation and installed acceptance remain required.

## Independent readiness repair ownership

Use persisted dispatch ticket issued/dispatch_started and no-effect challenge rules in family contract. Expired/revoked lease prevents new effect; authenticated executor may report a previously started outcome after expiry. Every canonical completion is idempotent by exact receipt/artifact digest; contradictions conflict. All initial settlement, terminal replay, no-effect authorization reuse and recovery readers verify canonical import/challenge provenance. Crashes around quarantine/import Git CAS/response never turn uncommitted bytes into accepted evidence.

- [ ] SC4: Corrupt provenance/blob on each independent journal/coordinator/recovery reader refuses settled assertion/authorization reuse.
- [ ] SC5: No-effect evidence before current challenge/failure is rejected; real fresh inspected absence settles once without caller timestamp trust.
- [ ] SC6: Lost begin_dispatch response/retry never returns invocation permission again; late completion records truth after lease expiry without enabling another effect.

## Current delivery sequence — local source, publication, Lab (2026-10-05)

The Captain's local-first instruction supersedes earlier scheduling prose that
requires unfinished installed acceptance before downstream source implementation.
Declared dependencies remain whole-task acceptance dependencies; they are not
removed, marked done or bypassed by a scheduler status change. A source checkpoint
allows the next source scope only after its required producer contracts are
integrated at an exact revision, relevant `bin/ace-test` package suites and
`bin/ace-test-suite` have executed successfully on the combined source, and an
independent reviewer has approved that exact candidate. Record revision, commands,
invocation-bound receipts and verdict in the existing task. Any subsequent
producer change requires affected consumer verification and fresh review.
Installed criteria remain open and their owning task cannot close until all of
its criteria pass. Unsupported or unproved protected execution continues to
refuse; no same-UID/mock fixture substitutes for real native/multi-UID evidence.
This sequencing decision authorizes no Lab SSH, protected probe, VM experiment,
filter retry, native permission bypass or deployment.

The integrated and independently approved xz9.0 source checkpoint may enable
this slice's boundary-failure source implementation before xz9.0 installed
acceptance finishes. Reverify combined authority/receipt/restart/duplicate/no-effect
cases; all genuine descendant, native and multi-user acceptance stays required.
