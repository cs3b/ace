# Test responsibility map: review campaigns

| Behavior | Risk | Layer / file | Acceptance |
|---|---|---|---|
| Identity, policy validation, canonical hashing, clean streak | High | atoms/campaign_contract_test.rb, atoms/campaign_projection_test.rb | SC1, SC4, SC6 |
| Atomic storage, corrupt record, replay and concurrent starts/writes | High | molecules/campaign_store_test.rb | SC2, SC4, SC6 |
| Session completion/checksums, no-op/failure, verified findings | High | molecules/campaign_evidence_test.rb | SC2, SC3 |
| Partial scope recovery, retained findings, contract successors, stale evidence | High | organisms/campaign_manager_test.rb | SC1-SC4 |
| Public CLI JSON/errors/dry-run/restart and old dispatch | High | commands/campaign_test.rb, feat/campaign_cli_test.rb | SC2, SC6 |
| Existing attempt accepts current campaign and rejects stale/self-approval/artifact drift | High | ace-assign/test/feat/campaign_receipt_test.rb | SC5 |

Pure atom tests do not mock logic. Persistence/evidence tests use temporary filesystem artifacts. Manager tests inject live revision readers where Git itself is irrelevant. Public entrypoints and assignment integration use real isolated Git repos, execution metadata fixtures and fresh processes. Fixtures test deterministic contracts; they are never reported as real paid provider execution. Include mixed identities, empty contract, policy conflict, mixed head/base, missing/corrupt reports, incomplete coverage, reused reports, contradictory replay, earlier unresolved High, resolved High non-clean, reopening, policy drift, unknown campaign and non-mutating dry-run controls.

Round-7 controls: full PR rejects any delta reference even with an inventory; explicit delta scope still accepts the pinned exact reference. A later empty terminal High assessment clears the claim but blocks the old approval until completed current coverage. Real Git without gitignore admits untracked ACE-private artifacts and rejects outside untracked source plus tracked/staged changes, including tracked files inside .ace-local.
