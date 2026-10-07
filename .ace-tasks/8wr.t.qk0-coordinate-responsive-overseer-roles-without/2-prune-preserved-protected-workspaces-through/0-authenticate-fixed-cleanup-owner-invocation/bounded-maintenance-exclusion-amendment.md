# Bounded maintenance exclusion acquisition

Source-design independently approved by root on 2026-10-08; implementation awaits frozen source review. Existing physical preview request has one absolute monotonic five-second deadline; no deadline increase or asynchronous Thread timeout is permitted.

`LaunchLifecycle#with_execution_slots` accepts optional `deadline:` supplied by the original preview handler, never reset. A supplied deadline is finite monotonic numeric and must remain future at each owner boundary. Existing callers without it retain blocking behavior.

Deadline-bearing acquisition is fail-fast: existing `LifecycleExclusion#with_exclusive` uses `LOCK_EX|LOCK_NB`; existing authority mutex uses `try_lock`; retained Inbox inventory/event lock owners use their existing locks with `LOCK_NB`. Busy or expired admission yields typed `AttemptErrors::MaintenanceBusy < EvidenceUnavailable`, without invoking the consumer block. Herdr's existing store raises its own typed lock-unavailable error, translated only at the maintenance owner. No arbitrary exceptions are classified as busy.

Sorted complete original/candidate slot inventory, protected root verification, immutable canonical contexts, retained Inbox inventory, all-context rechecks and reverse unwind remain unchanged. Any partial acquisition unwinds before refusal. A supplied deadline is checked before/after authenticated owner reads and immediately before the block; this contract bounds contention and refuses expired work, not preempting Git or filesystem syscalls. Physical preview must independently preserve its remaining absolute budget in its maintained bounded readers.

All lock-file opens on this deadline-bearing path use nonblocking opens and regular-file validation to avoid FIFO waits. No new lock or authority ledger is introduced. No current pointer or status can substitute eligibility proof.

Controlled tests: real temporary slot/inventory/event lock contention, contended injected authority mutex, expired/invalid deadline, later-slot failure releases earlier locks, ordinary blocking caller remains valid, and original complete maintenance transaction succeeds with deadline. No root/native/systemd probes.
