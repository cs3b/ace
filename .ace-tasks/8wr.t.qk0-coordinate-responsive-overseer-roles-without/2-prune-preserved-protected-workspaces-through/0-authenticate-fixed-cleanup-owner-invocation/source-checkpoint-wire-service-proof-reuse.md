# Wire-local immutable service proof reuse

Source checkpoint only; independent review and integration are required. No task closure, installed Lab acceptance, native probe, physical cleanup change or public deadline increase is claimed.

## Scope and preserved checks

EvidenceJournal reuses an already fully authenticated canonical inventory for exact event chains and introduction queries within its existing wire operation. One additional raw service-record slot retains only Git/JSON decoding and accepted immutable record-chain proof. Its key includes journal instance, repository/ref/checkout/mode/read boundary, exact commit, evidence reader, authorizer and request ID. Every caller receives an isolated copy. Nil, corrupt and failed reads are never retained; failure evicts the slot. Nested/thread operations remain isolated.

Terminal evidence validation remains outside the raw slot and runs on every read, including pending service-read-view semantics. Implicit ref selection stays fresh; current peers, role/policy admission, original exclusions, prefix checks and final CAS are unchanged. No callback verdict, current authority or grant is cached.

## Executed evidence

All reports below are retained under this worktree `.ace-local/test/reports/`:

- Assign operation owner: `assign/73daff43-953c-4137-9e8d-416b9b57a06a`, PASS 12/98. Same/different commit and full owner key, fresh implicit ref, mutation isolation, missing/corrupt/error eviction, nested/thread lifetime and no cross-wire reuse.
- Actual Git journal: `assign/afb513ec-41b4-4f92-95ea-fdaefa62e183`, PASS 23/136. Actual interleaved/corrupt history remains validated. Fresh terminal callback changes verdict within the same wire operation, refuses and evicts; restored evidence must be read again.
- Profiled actual cleanup selections: `lab/d64a956f-3291-40b1-9f62-1eb692421e8a`, PASS 4/67. Dead-root replay, replacement-root retained-success readback, immutable completed-failure conflict and replacement at lower CAS all keep their original assertions.

Temporary diagnostic wrappers were removed from the committed fixture; computed measurements and earlier failed reports remain in `.ace-local`. Final uninstrumented selections 69/411/419/846: `lab/d32899be-1ddf-4187-9c9a-6fdd7e0b49b3`, PASS 4/67, zero failures/errors, 1m28s. No profiling wrappers or fixture changes were present in that run.

## Measurements and limits

Baseline replay `lab/1f4b12a0-d1b8-4052-839a-eed7a780c52f` failed at the unchanged 5-second admission deadline: 5.007 seconds and 114 Git calls recorded before client return. Those counters describe a partial operation, not an equivalent completed RPC. Final profiled replay succeeded in 2.660 seconds with 74 Git calls and all three assignment admissions reached. Baseline successful recovery `lab/d52360c3-1a3a-4aa6-98ba-74a6b047381a` took 9.452 seconds / 204 Git calls; final profiled successful recovery took 5.672 seconds / 163 calls. Recovery preserved 46 fresh ref resolutions, six prefix checks, eight assignment admissions and two CAS writes.

Profiles are `.ace-local/test/profiles/before-cleanup-dead-root-replay.json`, `before-cleanup-retained-success-succeeded.json`, `cleanup-dead-root-replay.json` and `cleanup-retained-success-succeeded.json`. Method timings are inclusive and cannot be added. Lock timings include work; lock-wait/queue contention was not separately measured. This checkpoint proves eliminated repeated immutable work, not a complete latency guarantee under every load.

An intermediate inventory-only run `lab/87fc1a30-b0bb-4e8f-8d57-3f31b1ad1205` refused before physical dispatch with CanonicalReadSnapshot `unsupported_source` (1/6 failure). Its exact cause remains unclassified and was not reproduced by later controlled selections. No snapshot permission, fixture-source rule or refusal was weakened to pass. The inventory-only replay still timed out in `lab/531fb790-d25c-4828-9d2a-545f1c789a0f` (1/24 failure). An initial unit identity assertion failed in `assign/e7fc3f5c-5b64-4a0e-9ddc-3599bb1c2aa8`; it was corrected to content plus zero redundant-read assertions because the existing owner intentionally returns a deep-frozen projection copy. All failures remain retained.

## Independent review and integration

Root APPROVED exact author commit `4545dacce3d5760d72f12733334a44c738525ad2` after source and test review. The retained raw record remains exact-commit and operation scoped; each terminal evidence callback runs fresh, failures evict the raw slot, callers cannot mutate retained data, and current-ref/admission/CAS checks remain unchanged. No findings for this bounded optimization.

Directly inspected final uninstrumented controlled cleanup receipt `d32899be-1ddf-4187-9c9a-6fdd7e0b49b3`: 4 tests / 67 assertions, no failures/errors/skips. Integrated as `e843b65be`; main operation test file passed 12 tests / 98 assertions, receipt `89225bec-8d80-4ddf-8a11-3cb1b902e457`. No extra Lab profiling instrumentation was integrated. Remaining source and installed acceptance requirements are unchanged.

Full Assign fast regression on fixed main `524f284a8` passed 951 tests / 3968 assertions, no failures/errors, in 132 seconds: `assign/19772d54-ddb2-4332-acf2-d8515e715e96`. No source changed during the run. This verifies broader journal consumers, not installed Lab acceptance.
