# Direct Router fixture request scope

Base: `8f3380ba4`. Only EndcapResultOwnerFixture dispatch boundaries change: each actual Router dispatch receives its own EvidenceJournal.with_event_read_operation, matching the production Server lifetime. Registration preparation/transfer setup, subsequent requests, and scenario-wide reads do not share the scope. No product or journal authentication changes.

Executed controlled source checks in the isolated `codex-assign-request-scope-fixture` checkout:

- `bin/ace-test ace-assign test/fast/molecules/event_read_operation_test.rb`: PASS 6 tests / 36 assertions, receipt `5b638434-664e-4ab2-84c8-6c53afd451ce`. Covers immutable projections, fresh implicit current selection, old prefixes, nested/independent/concurrent contexts, refusal cleanup, and ordinary reads.
- `bin/ace-test ace-assign test/feat/authority/historical_rotation_test.rb:850 --timeout 120`: PASS 1 test / 34 assertions / 0 skips, receipt `692f2ddd-ed16-4059-963e-996c98ba678c`. Raw output confirms exactly `Ace::Assign::HistoricalRotationTest#test_actual_terminal_service_inbox_original_history_retirement_and_rotated_normal_reuse`, seed 5300, 47.304969 seconds. Existing controlled installed/kernel boundaries remain injected; actual canonical Git/history/service/Inbox retirement and rotated reuse assertions remain unchanged. The runner's old duration parser reports 0ms; raw elapsed is authoritative.

Prior measured baseline and Router-scope experiment remain in primary `.ace-local/test/performance-audit/continuation-20261008.md`: 53.47s versus 44.58s. This successor preserves the same 34 assertions and supports the scoped fixture correction, not a universal timing guarantee. Outer runner budget 120s does not change product deadlines. Five earlier feature timeouts remain separate unresolved evidence; this change does not establish their closure. Independent source review is pending.
