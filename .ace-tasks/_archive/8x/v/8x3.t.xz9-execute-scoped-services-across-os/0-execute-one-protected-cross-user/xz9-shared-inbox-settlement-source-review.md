# Shared Inbox settlement source review

Exact frozen SHA: `f44062226250f1cc8823bc7540b97e417013a8bd`, reviewed against approved `943444bcc28b3387d825a45624e6ef3ca99c9a0c` in isolated reviewer worktree. Verdict: **REQUEST CHANGES**.

## Verified finding

[P2] Inspect both retained copies before declaring inventory complete — `ace-herdr/lib/ace/herdr/organisms/inbox.rb:52–61`. The new inventory gathers live and archive filenames, deduplicates event IDs, then calls DeliveryRecordStore.load, which prefers the live file. Thus a corrupt archive/event.json is ignored whenever a valid live event.json exists. The shared predicate returns true with that corrupt/unattributable retained record, contrary to complete live/archive inventory and corruption refusal. An interrupted or abnormal archival state must not silently select its favorable copy. Under the existing no-create event lock, validate every existing retained copy and refuse conflicting, malformed, or unattributable duplicates; identical copies may be explicitly handled if supported.

## Independent executed evidence

`bin/ace-test ace-assign feat /Users/mc/Ps/ace/.ace-wt/review-9c2-runtime/.ace-local/review/inbox_inventory_boundary_test.rb`

21 tests / 125 assertions / 1 failure / 0 errors, immutable receipt `d7eb1077-89f8-41c4-8780-93b0aac614e2`. Regression uses the actual canonical Git journal, actual RSA signed consumed reconciliation and real retained filesystem records; adds corrupt archive/event.json alongside the valid live record, then expects EvidenceUnavailable. No exception was raised. Remaining inherited checkpoint tests passed. Earlier relative-path invocation `327f3927-00b3-4432-85d0-12bc0b7730ad` was a load error with zero executed tests and is not verification.

## Bounded assessment

The source-owned helper adds no public wire operation or fabricated peer. It shares context and canonical evidence verification, requires a current claim with signed consumed/completed agreement, and uses existing retained no-create locks. It compares supplied events to the same immutable commit and validates the chain; lifecycle callers must hold exclusion and use that selected commit in their eventual journal CAS. Historical snapshot validation alone is not a verified bypass and is not a separate finding. Actual scope-owner integration, complete startup and installed acceptance remain outside this checkpoint. No native probes or broad suite were run; no production files changed.
