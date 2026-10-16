# Independent Hermes source review, round 2

Verdict: **APPROVE**

Reviewed HEAD: `594938717252f7ec4e258a071beaff8fcd2e381a` in `/Users/mc/Ps/ace/.ace-wt/ei9-shared-hermes`. HEAD was verified before inspecting the correction and again after the executed checks. `git status --short` was empty both times. No author source was changed by this reviewer.

The prior P1 durability finding is resolved. `HermesAtomicWriter.write` now performs write → chmod → file fsync → final rename → parent-directory fsync before returning. Its shared `sync_directory` barrier opens the directory with NOFOLLOW, verifies the descriptor is a directory, and propagates failure. The ingress recovery branch also invokes this barrier for an existing first-body filename before assigning `body_sha256`. Both fresh publication and recovery therefore establish the directory-entry durability barrier before the receipt metadata commit and subsequent Telegram offset advancement.

Failure ordering was inspected in the real call chain: directory fsync failure escapes the writer or recovery barrier, becomes IngressUnavailable, and escapes Poller's per-event ContractError rejection handler. Poller's outer failure handling invalidates coverage while retaining the old cursor. The reserved ingress sequence and original file survive for recovery; a replacement replay body does not overwrite the first body. The new regressions independently execute both fresh-file and recovered-file barrier failure, asserting offset 0, absence of a body digest, stable sequence, original-body retention, and successful eventual delivery of that first body. Their successful path asserts directory barrier precedes receipt metadata, which precedes offset 11.

## Independently executed checks at this HEAD

- Original reviewer PoC, unchanged: `../bin/ace-test --config-path ../.ace-local/ei9-review/runner.yml --filter test_ingress_directory_is_synced_before_telegram_offset_advances` from ace-hitl-hermes: **PASS**, 31 tests / 190 assertions / 0 failures / 0 errors. The custom config runs the original independent test plus existing/inherited transport cases. Report: `.ace-local/test/reports/hitl-hermes/50d4e1c1-53fe-4e5b-8a5d-3a4a7f6b9fa6/`.
- Affected primitive and transport suite: `../bin/ace-test test/fast/molecules/hermes_atomic_writer_test.rb test/fast/transport/multi_project_relay_test.rb`: **PASS**, 21 tests / 121 assertions / 0 failures / 0 errors. Report: `.ace-local/test/reports/hitl-hermes/55fff1cf-3a92-4eba-858d-d285a9e78013/`.

No additional actionable source finding was established. The original independent PoC now passes and the barrier-failure/recovery ordering has executed coverage. The first round's full Hermes (180/1027), HITL policy/TLS (14/84), and contract (22/137) checks passed at `289411820f77d5b79006700c808a5de661eb076c`; they are historical evidence, not claimed as new-HEAD runs. The author's new-HEAD full Hermes pass (184/1061) was reported to this reviewer but was not independently repeated because the targeted checks exercise the complete correction and no new concern justified broadening this round.

This is approval of the reviewed source only. It neither overrides Captain's all-group bidirectional communication requirement nor closes the separately recorded installed-domain/operator-question/one-poller-handoff gap. Prior rejection evidence remains valid for its old commit and is preserved in `.ace-tasks/8xf.t.ei9-wave-3/9-route-project-hitl-and-delegated/evidence/hermes-durability-r1/`. No deployment or publication was performed.
