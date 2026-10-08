# Bounded request-service inventory reuse

Base e00eee602. Existing five-second public claim exchange remains unchanged. No source or fixture timeout, grant, peer, exclusion, policy, final ref or CAS check is removed.

## Measurement

Actual request_service-only fixture uses real temporary Git, Authority Client/Server, transfer, candidate/review history and mutation owner. It intentionally stops before export/provider execution and requires zero effects. The expanded measurement wraps maintained source methods, not substitutes for their answers. Times are inclusive/nested and must not be summed. One before/after sample is diagnostic, not a stable benchmark claim.

| Metric | Before | After |
| --- | --- | --- |
| with_assignment |3 calls /3.145s|3 calls /2.214s|
| canonical_event_inventory! |3 calls /0.726s|3 calls /0.208s|
| actual canonical history walks |3|1|
| captured Git subprocesses |24|16|
| read_events |19|19|
| read_event_snapshots! |19|17|
| fresh ref reads |25|25|
| mutate |1|1|
| provider effects |0|0|

All three inventory queries select the same exact pre-CAS commit. Remaining distinct event/history prefixes, fresh ref reads and mutation writes are not memoized by this change. Captured subprocess counts cover BoundedProcess history reads, not every Git subprocess; no whole-process count is claimed.

## Source invariant

Existing with_event_read_operation owns one event selection and one full inventory selection until ensure restores its previous thread context. Inventory key includes actual journal object, repository/ref/checkout, evidence mode, read-boundary object identity and exact40hex commit. Protected mode only; no HEAD/name, local mode or caller grant reuse. A different identity/commit or failed inventory clears the prior inventory before decoding. Only the existing complete first-parent/raw-blob verified deeply frozen projection can be stored. Event selection eviction does not evict the independent full inventory; this does not create a multi-history event cache. Separate operations, threads and nested contexts do not share snapshots. Fresh peer/ref/exclusion/CAS admissions continue to execute independently.

## Executed evidence

- Expanded baseline request measurement PASS1/10,25.021929s,seed46889: git/e96eb146-9ca2-4f9e-878f-469c9c1a348f. Local request-admission-baseline.json retains exact counters.
- Same measurement after source change PASS1/10,18.75s: git/0c005afb-6bd4-43e8-919a-1a32cbd5601f. Local request-admission-after-one.json retains exact counters.
- Maintained operation-read unit file PASS9/62: assign/81ffca76-269e-4b5f-af10-417b2a5bffa1. Covers deep freezing, changed commit/repository/ref/checkout/read owner, failed inventory, local/name refusal, thread/nested/ensure isolation and unchanged existing event tests.
- Actual Git inventory test PASS1/16,3.024888s,seed43494: assign/93ec90b0-11aa-4dd4-a847-17ca6bf6cbad. Runs with protected operation reuse enabled; every omitted event/assignment, duplicate blob and rewritten raw serialization still refuses. Valid historical prefix is recomputed after refusal.
- Initial measurement instrumentation failure retained1aabe6af1/7: attempted to wrap nonexistent original_registration_context!, before measured admission. Corrected to actual authenticate_inventory_registration!; no production failure or performance evidence inferred.

Actual composed authority-loss regression PASS1/93,56.84s: git/e7a647ec-e6f9-4628-a0da-d62c6323fb8c. It removes the real authority socket and refuses public request/status/Delivery, retains the original claim/ref/selectors, then completes/replays exactly one original effect after restart. Independent review remains required. This bounded checkpoint does not close qkb or certify deployed latency.
