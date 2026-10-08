# Cleanup admission immutable-read experiment

Base: `6a1e9e7aeaee13aab98237f1fbce5e613f281aef`; isolated branch `codex/cleanup-admission-read-scope`. This bounded experiment does not close cleanup acceptance or the aggregate test-file timeout.

## Scope and test responsibility

Reuse existing `EvidenceJournal.with_event_read_operation` only around the held canonical snapshot admission in `ProtectedCleanupOwner#handle`. Each preview/execute/inspect admission still performs fresh peer and original-owner checks. The existing decoder selects exact journal identity, assignment and immutable commit; current-ref reads still select freshly and changes discard the previous memo. The memo ends when the held read exits, before Installer callbacks. No new cache, authority, wire field, timeout, history-proof bypass or fixture simplification is added.

| Responsibility | Verification |
| --- | --- |
| All three transport routes retain only one operation's frozen event read, then discard before physical callbacks and next connection | New controlled socket/read-lifetime test |
| Changed current commit reads freshly; explicit original commit is not replaced by tip | New controlled socket/read-lifetime test |
| Admission refusal invokes no effect; cleanup and next connection's peer admission remain fresh | New controlled socket/read-lifetime test |
| Existing exact-key, nested/thread, failed-read and ordinary-mode semantics | Existing Assign event-read operation tests |
| Actual canonical dispatch, root read-only snapshot, receipt import and replay | Existing cleanup dispatch scenario at line69 |
| Actual original inspection/challenge, no-effect import and storage-free replay | Existing cleanup dispatch scenario at line219, including existing counters |

The new test controls only native/admission collaborators and the decoder boundary to isolate transport lifetime; it does not claim canonical admission proof from a fake journal. Existing composed scenarios retain real temporary Git, actual canonical owners and local sockets, with injected native/Installer observations. No native, installed, privileged or external probe occurs.

## Measured comparison

Same inspected line219, same base and scenario, original test unchanged. Each run selected exactly one method, so randomized seed did not change test ordering. Baseline seed31881 and successor seed56242 are distinct; these are not a same-seed randomized suite reproduction.

| Measurement | Before | After |
| --- | --- | --- |
| Actual tests/assertions | 1/27 PASS | 1/27 PASS |
| Whole scenario seconds | 34.059685 | 33.295368 |
| Git calls / inclusive seconds | 811 / 15.583 | 801 / 15.289 |
| `read_events` calls / inclusive seconds | 290 / 9.459 | 290 / 8.581 |
| Full event history walks | 23 | 23 |

Baseline report `lab/66654dd5-7c0a-4eeb-8725-d8c30cb3076e`; successor `lab/323d2a37-d93b-422b-96e3-a9e09a37b89f`. Counter times are nested and must not be added. The deterministic change removes10 Git calls; the small wall-time difference is not evidence of a reliable general speedup. Existing public status assertions still require exactly one full history walk. This does not solve or justify increasing the retained120-second aggregate file timeout.

New transport lifetime tests: `lab/7d971458-7b8e-4a13-9abd-cc57e42b8eb9`, PASS3/57, 0.015057s, seed49240. Existing primitive owner: `assign/2d44c7a7-c221-4ed3-b385-d8c392228cc7`, PASS6/36, 0.000980s, seed47050.

Actual positive root dispatch/held read-only snapshot/import/dead-root replay: `lab/6045e11a-5b5e-4813-bf04-23b86552f15b`, PASS1/27, 30.01s. All executed handles are terminal.

Preserved unsuccessful observation: `lab/e7f278a9-54bb-484a-b160-694a41441d95`, errors3/0 before admission because the new test used ordinary `/tmp` ancestry. Fixed only test placement to the existing protected fixture's private home-directory convention. A subsequent attempted `--seed` flag was rejected by ace-test before execution; no test receipt or same-seed claim is fabricated.

## Fixture duplication inspected separately

`EndcapResultOwnerFixture#fixture` unconditionally appends synthetic `candidate(1)` after original binding. `ProtectedServiceBoundaryFixture#prepared_submission` subsequently performs actual candidate generation1 transfer/import before review. This redundant predecessor remains unchanged. A separate explicit fixture preparation option could remove it for actual-import scenarios after checking consumer expectations, but no shared mutable fixture or removal of canonical fault coverage is proposed here.

Independent review remains required; this author receipt is not an approval.
