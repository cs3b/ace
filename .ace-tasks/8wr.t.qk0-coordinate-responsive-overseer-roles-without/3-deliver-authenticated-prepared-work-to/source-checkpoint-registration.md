# Prepared registration source checkpoint

Candidate source slice; independent review and integration are pending. This is
not qk0.3 completion. Authenticated prepared fetch, original adapter activation,
scoped queue consumers and the protected task-context command entry join remain
separate implementation work.

The public registration operation now accepts only one fixed candidate upload
with exact prepared head/tree, manifest SHA and final-definition SHA. The authority
verifies the complete prepared tree, derives the final definition, and commits that
definition and the exact received bundle bytes in one existing JournalMutation.
The same final definition cannot replace its original raw bundle with another
valid transport advertising the same head. Reservation requires the accepted
task/scope selection. Public LaunchDriver and CLI require the original bundle;
the CLI reads bounded held regular files without final symlink following. Inventory
and the maintained Overseer consumer agree on prepared reference/size/digest fields.

Controlled executed receipts (all under this worktree's `.ace-local/test/reports`):

| Case | Terminal result | Receipt |
| --- | --- | --- |
| Actual Server framing, atomic registration, replay/raw-bundle replacement | 3 tests / 49 assertions PASS, 6.83 s | assign/206c1b10-575b-41a4-9dc1-0119ecb354d2 |
| Actual default two-task producer and materialized selected subtree, Git transfer | 3 / 22 PASS, 1.71 s | assign/7245870b-d359-41cb-8bee-0e5b228b062a |
| Mandatory public bundle option, help, held regular reads and input refusals | 9 / 94 PASS, 93.31 ms | assign/133c9ad9-4d54-49f1-a263-152505980848 |
| Real driver lost response/reservation replay | 1 / 6 PASS, 7.37 s | assign/a5bc2430-2928-4646-abbe-baf29ba4c3ba |
| Actual original CLI/driver live stream, late prompt ACK, native input drain, fresh scope close | 1 / 76 PASS, 39.47 s | assign/872cdd8a-f206-4107-98f6-3cd64f4658e6 |
| Parent activation refusal, release and next reservation | 1 / 19 PASS, 15.38 s | assign/59f5af3b-289a-490e-a5fc-a934454b5d87 |
| Inventory exact prepared fields at retained commit | 1 / 29 PASS, 8.70 s | assign/562f2617-3b71-439b-922e-d2f12647b787 |
| Maintenance original/candidate/public registration producer | 1 / 36 PASS, 23.19 s | assign/b041ed0f-3b0a-4f89-aecb-0a3f06b6f65b |
| Actual historical public inventory transport | 1 / 21 PASS, 13.63 s | assign/842d35f4-85bb-45bf-b9cb-3df8b426c111 |
| Overseer exact schema and malformed prepared selector refusals | 4 / 23 PASS, 0.93 ms | overseer/c15fb6af-a208-4eea-b046-7b2155ff323e |
| Retained review after actual accepted terminal receipt | 1 / 15 PASS, 19.64 s | assign/fe7d0728-a814-46bb-84eb-862b8fb15b4f |

Failure history is retained. The original full lifecycle run was explicitly
cancelled (exit 130, no completed receipt) for prolonged quiet output; no failure,
timeout or PASS is inferred from that cancellation. The selected live-stream case
then failed twice at late closure (d60f8db3 and 521aaa57), because its fixture
treated a submitted prompt ACK as lifetime input-drain evidence. The repaired case
requires actual accepted native input inhibition and a fresh mutation after the
close owner's retained pre-effect running reply. No production proof was relaxed.
A diagnostic run fe0690b4 reported a canonical Git blob batch post-launch process
failure (`Operation not permitted`); this was not attributed to a baseline.

The complete Endcap result file executed 13 tests / 194 assertions with one error
(fd2fbade, 2 m 50 s): a retained-review fixture appended a bare terminal transition
without the required accepted receipt provenance. Its repaired selected successor
uses the actual canonical artifact reader and AttemptCoordinator.finish and passes.
Historical registration fixture failures d5c734ef and 2678f7e0 exposed missing
candidate/launcher scratch directories; the corrected public successor passes.
Earlier retained receipts also preserve the test-only binary/UTF-8 comparison and
incorrect registration-event lookup errors. No receipt is erased or upgraded.

The complete migrated lifecycle file executed 33 tests / 500 assertions with one
failure and one error (8117caab, 7 m 45 s). The other 31 cases, including actual
driver/control/drain paths, passed. The corruption fixture reused one journal for
four fresh prepared artifacts under the same mutation ID; distinct private
scenario roots repair that invalid exact-replay assumption. Its selected successor
passed 1 / 39 (3d61672e, 8.80 s). The pagination fixture assumed all remaining rows
fit a second 16 KiB frame; prepared references correctly require more pages. Its
successor follows each bounded page at the original commit, checks no duplicates,
and passed 1 / 16 (64c9f74c-99a4-46f0-a027-99da1c288a80, 3 m 6 s). Neither
failure required a production cap/proof change. Verification is the complete
executed file plus its two repaired selected successors, not a claimed rerun of
the whole file. There are no live test sessions.
No native, installed, protected-process, provider, mount, systemd or Linux probe
was run. Runtime/kernel/filesystem admission boundaries are controlled fixtures;
actual file reads, Git, framing, journals, producers and maintained consumers run.

## Independent integration review

wave_n0n approved exact author6344b518c after source review of registration, original raw bundle selection, CLI/framing, prepared scope and producer/consumer inventory. Root integrated as b16db3a96 after cleanup input cross-package fixes; merged historical_rotation preserves both migrations. Root executed actual prepared-registration target on that joined tree: 3 tests/49 assertions PASS6.93s, receipt `e80d4260-ca2d-410b-b2fb-717a08b40f46`. Joined Lab input/recovery also passed9/74. This approval remains registration only; original prepared fetch/worker/queue/context consumption is not delivered by this checkpoint.
