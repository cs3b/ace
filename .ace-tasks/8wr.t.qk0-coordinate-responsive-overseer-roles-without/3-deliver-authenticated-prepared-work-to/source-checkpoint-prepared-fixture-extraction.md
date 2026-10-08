# Prepared-flow test fixture ownership

Base `8c66a0484`; isolated branch `codex/prepared-flow-fixture`. Production code, qk0.3 acceptance requirements and test deadlines remain unchanged. Independent review is required before integration.

## Diagnosis and bounded change

`PreparedManagedFlowTest` required the concrete `PreparedWorkFetchTest` file and inherited its12 tests, in addition to its own2. Loading only the managed file therefore registered the parent12 and subclass14, instead of the intended2. `PreparedWorkerTest` did the same with its own9. Loading all three files registered47 cases for23 unique scenarios.

Retained root receipt `c7a475ca` timed out120 seconds while running parent fetch cases, before either managed case appeared. This was not evidence that actual managed execution failed or completed.

Extract only shared helpers into `test/support/prepared_work_fetch_fixture.rb`, which defines a module and no runnable test class. All three concrete classes directly inherit `AceAssignTestCase` and include that module; neither consumer requires another test file. Helper bodies and all fetch/worker test bodies are unchanged. Managed test bodies are unchanged except the positive worker constructor now receives the existing `controlled_workspace_reader` fixture.

The extraction exposed a previously masked managed fixture failure: its constructor selected the production workspace reader instead of the controlled native boundary used by other source tests. Receipt `386ea21f-1665-4522-86a1-8127ffdc6cb7` selected exactly2 cases and errored2/18 before provider execution, with `Original lifecycle reader admission is unavailable`. The existing fixture still executes actual workspace provisioning, retained projections, real files/marker bytes and flock checks; only declared installed mount/ACL/identity observation boundaries are injected. No production grant or validator is weakened.

## Test responsibility and executed evidence

| Source owner | Responsibility | Actual verification |
| --- | --- | --- |
| Prepared fetch12 cases | Actual Server/Client/Endcap/Git original bundle selection, release and refusal | Two disjoint exact six-method selections, preserving all12 once |
| Prepared worker9 cases | Original activation, scoped CLI, original context entry, retained workspace and refusal | Whole file, exactly9 cases |
| Managed flow2 cases | Real managed preparation/registration/release/fetch/queue plus original public candidate/review/result | Whole file, exactly2 cases |

Managed file `assign/2663523c-0ef8-433e-b7fd-cba09fc040ef`: PASS2/86, 53.217690s, seed63100. The original result-production path actually reached its maintained public commands; a provider response string did not stand in for queue completion or result evidence.

Worker file `assign/9b1a233e-540f-4034-b734-e0bb81928e30`: PASS9/130, 129.616090s, seed20652. Effective runner configuration was default by-target, `per_file:false`, `timeout:null`; this is not a claim that the worker file fits the separately retained per-file120-second budget.

Fetch first selection `assign/db1b65ad-297a-4bd1-912e-0010d4d39ee8`: PASS6/92, approximately78.68s. Exact selectors10/32/53/78/91/126 in the extracted file cover real large bundle transfer, original release pin, encoded envelope bound, unavailable bundle, changed release pin and malformed transfer selectors.

Fetch second selection `assign/3f89ecde-1c55-417c-ae44-b68361943a48`: PASS6/67, approximately65.87s. Exact selectors175/192/220/261/269/283 cover authenticated descendant/original anchor, changed current artifacts, replaced current mapping/missing original retention, unissued original, foreign birth/role/purpose and exact retained issued bytes. All12 fetch cases passed once across these two disjoint selections. All test handles are terminal.

An attempted `--filter` was rejected as a filename pattern and selected no tests (`b02312c0-b0b4-43bd-8a52-b1a026d2b426`); it supplies no verification. Corrected verification uses existing exact line selection, whose loaded/executed identities are checked by the runner.

Native/installed/process identity and provider boundaries remain controlled as documented in the original fixtures. No Lab probes, external provider calls, publication or root-file edits occur. This is fixture/test-layer repair, not qk0.3 closure or a general performance claim.
# Independent integration verdict

Root APPROVE `8e0e197af5c2d1ef6258a33b3f964b5831afda84`: reviewed helper-only module extraction, preservation of runnable fetch/worker cases, class composition and the managed worker's existing controlled workspace-reader seam. No production guard or timeout was weakened. Integrated `f9e246602`; full managed-flow file now runs exactly its two scenarios and passed 2 tests / 86 assertions in 43.93s, report `assign/8837d346-e4d2-4f03-a358-5eaef5c77e06`. Earlier 120-second timeout is superseded for this file, not for every package or final suite.
