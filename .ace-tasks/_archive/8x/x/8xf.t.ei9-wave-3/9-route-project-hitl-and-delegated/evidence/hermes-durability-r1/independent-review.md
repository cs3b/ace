# Independent Hermes source review

Verdict: **REJECT**

Reviewed commit: `289411820f77d5b79006700c808a5de661eb076c` (`codex/ei9-shared-hermes`), against `2e9005f39`.

Scope: source changes in ace-hitl-hermes, ace-hitl and ace-hitl-contract. Read repository AGENTS.md, docs/tools.md agent practices, and the as-review-run skill/workflow. This is the requested independent adversarial review; no author source was edited, deployed or published. The review workflow's authoring/fix phase does not apply to this read-only reviewer assignment.

## Blocking finding

**[P1] Flush the ingress directory after publishing its body and before committing receipt metadata / advancing the Telegram offset.**

`ace-hitl-hermes/lib/ace/hitl/hermes/transport/relay.rb:346` publishes the ordinary ingress body and immediately records its body digest. `HermesAtomicWriter.write` fsyncs the temporary file and renames it to the final filename (`molecules/hermes_atomic_writer.rb:42-45`), but never fsyncs the containing directory. `ingress_box` fsyncs the project directory when creating `.ingress`; that does not flush the later file rename inside `.ingress`. Subsequent journal commits flush only the separate transport state directory.

For an unavailable authority, `receive` therefore returns unresolved with a durable journal/body digest, and Poller commits offset 11, without ever fsyncing the `.ingress` directory that contains `inb-1.json`. After a host/power crash, the file's contents may have been flushed while its final directory entry is lost. Telegram has already been acknowledged past the update, and drain can only report an unavailable retained body. This violates the explicit ordinary-body durability-before-offset requirement and can permanently lose a Captain reply.

Independent executable check: `.ace-local/ei9-review/durability_test.rb` instruments real File#fsync calls, uses real project/ingress folders and journal, submits an ordinary request, makes its lifecycle unavailable, and processes one Telegram update through the actual Poller. It confirms offset 11, unresolved status, stored body digest and existing body file, then fails because no fsync of `.ingress` occurred. This demonstrates the missing durability barrier; it does not claim to simulate filesystem power loss.

Required correction: fsync the ingress directory after the final body filename exists and before committing `body_sha256` / returning receive success. Cover both fresh publication and recovery of a file that exists after a previous process crash. Let failure preserve the Telegram offset. Add a regression that checks this ordering. This may be implemented at the shared writer if all writer callers need the same durability contract, or explicitly at the ingress owner.

## Executed checks

- `ace-hitl-hermes/../bin/ace-test`: **PASS**, 180 tests / 1027 assertions / 0 failures / 0 errors, 32.81s. Report: `.ace-local/test/reports/hitl-hermes/fc72d2ea-e3f0-4da3-ab19-c55bde86dabc/`.
- Explicit Hermes transport files (`multi_project_relay_test.rb`, `registry_endpoint_test.rb`, `tls_client_test.rb`): **PASS**, 30 tests / 156 assertions, 1.63s. Report: `.ace-local/test/reports/hitl-hermes/140a6618-03e3-4184-8c16-9c9c7338bff7/`.
- Explicit runtime routing/TLS routing/managed publication/Telegram transport files: **PASS**, 58 tests / 258 assertions, 7.31s. Report: `.ace-local/test/reports/hitl-hermes/d9a11aed-f469-4c65-bdc4-2945e24f4469/`. An additional directory argument did not select transport tests; the explicit transport command above corrected that selection.
- `ace-hitl/../bin/ace-test test/fast/lifecycle/proposal_policy_test.rb test/fast/lifecycle/tls_service_test.rb`: **PASS**, 14 tests / 84 assertions, 14.18s. Report: `.ace-local/test/reports/hitl/9b89a16c-5481-46c2-afff-68e935f7e895/`.
- `ace-hitl-contract/../bin/ace-test`: **PASS**, 22 tests / 137 assertions. Report: `.ace-local/test/reports/hitl-contract/58bec0b0-2e43-47e0-bf51-32a16d750a4f/`.
- Independent scratch durability check, executed through `../bin/ace-test --config-path ../.ace-local/ei9-review/runner.yml --filter test_ingress_directory_is_synced_before_telegram_offset_advances`: **FAIL**, 27 tests / 140 assertions / exactly one failure. The custom configuration also ran inherited/existing transport tests; only the new durability assertion failed. Report: `.ace-local/test/reports/hitl-hermes/4570e979-f6af-4ef4-8f26-d4f611c9b824/`.

## Other reviewed boundaries

Source and executed regressions support explicit channels/v2 project authorities with no default fallback; triple request keys; same-group/same-ID authority separation and restart; exact persisted Reply correlation; old-journal refusal without rewriting; ordinary retry isolation across project outages; retained-first-body recovery; secret answers excluded from ingress bodies and body digests; route/Captain fingerprint refusal after reconfiguration; canonical disjoint channel roots and project-folder alias refusal; canonical checkpoint project equality; and real TLS identity / stalled-handshake rejection. No additional concrete blocking source finding was established during this review. Passing process-crash recovery tests do not cover the missing filesystem directory durability barrier above.

The 176-second proposal feature suite was not repeated, as instructed; its author-reported pass is not represented as independently executed evidence here. No installed-domain, operator-question or one-poller-host-handoff completion is claimed. The remaining genuine host operator question gap is explicitly recorded in `.ace-tasks/8xf.t.ei9-wave-3/9-route-project-hitl-and-delegated/host-question-context.md`; Captain's all-group bidirectional communication requirement remains controlling. This verdict is source-only and must be revisited after the durability correction.
