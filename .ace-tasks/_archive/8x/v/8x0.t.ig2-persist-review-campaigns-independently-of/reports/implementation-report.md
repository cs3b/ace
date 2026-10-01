# Implementation report: t.ig2

## Result and delivery ownership

`ace-review` owns durable campaigns: frozen requirements and policy, pinned whole-PR/local scopes, retained verified findings, logical rounds and separate historical convergence/current acceptance. Atomic locked storage and immutable finding snapshots retain history across commits and restarts. `ace-assign` supplies accepted collection, approval and check authority through its existing coordinator/journal and validates campaign results through its receipt verifier. There is no additional execution runner or journal.

Implementation worktree: `.ace-wt/codex-t-ig2-review-campaigns`; branch: `codex/t-ig2-review-campaigns`; base: `28c62024b5c732b278edb217a199f76ad64f9fc5`. [PR #354](https://github.com/cs3b/ace/pull/354) is published. Task `t.ig2` is done and archived through ACE tooling. Formal delivery uses managed assignment `8x0vrp` and campaign `8x0vs4`. Current-head approval, check receipts and final campaign consumption are recorded in the durable execution journal and PR evidence; this committed report does not certify a later commit.

The full chronological engineering log remains in [the previous report revision](https://github.com/cs3b/ace/blob/12fcf36782c7e35ef1f1b1b83ba5585e04401958/.ace-tasks/_archive/8x/v/8x0.t.ig2-persist-review-campaigns-independently-of/reports/implementation-report.md). This concise report retains the criterion map, implementation commits, material fixes and provenance without repeating superseded test totals. Failed runs and corrections are also retained in `test-failure-analysis.md` and `.ace-local/test/reports/`.

## Executed source verification

Original implementation source `bcb627d86` passed review all 994 / 3,152 assertions (four skips), assign all 751 / 2,749 (no skips), and the 50-package default suite 10,479 / 31,189 (24 skips). Artifacts: `review/8x0qn6/report.md`, `assign/8x0qr9/report.md`. Fourteen actual independent source reviews were performed; the last was clean. Requested reviewer `codex:sol:high@ro`, actual model `gpt-6-sol`; round-14 report SHA256 `c555f00bada2261b1f67bbc1cc9fa00caa2da04e2e0d6992b00fc68238829049`. These manual sessions used `--no-feedback` and do not count as formal campaign receipts.

Delivery source `f858b20a2` passed review all 996 / 3,171, assign all 752 / 2,757, all 50 default packages 10,483 / 31,217, docs all 213 / 579, provider all 400 / 1,041 and overseer all 252 / 1,008. Accepted historical test receipt: `8x0wcu`. Subsequent approval audit defects required a new candidate; this receipt cannot certify that candidate.

Repaired source `12fcf3678` passed all 50 default packages: 10,485 tests / 31,234 assertions, 24 skips, zero failures. Both owning all-target suites were launched at that source. Report condensation is subsequent bookkeeping; final exact-head verification must still be bound independently after it. The suite emits direct aggregate output without an aggregate report path. Reviewers inspect source read-only; coordinator-executed tests remain separate evidence.

## Criteria and executed cases

Cases below ran under deterministic package verification. Package test artifacts preserve the executed file list and outcomes; test method names identify individual cases. Source sessions for deterministic tests use controlled provider records, not evidence of live provider readiness.

| Criterion | Executed cases and observed controls |
|---|---|
| SC1 | `CampaignCLITest#test_public_json_dry_run_restart_replay_head_drift_and_acceptance` executes public commands in fresh processes against a real repository: three rounds accept at H1, H2 preserves counters and rejects stale finish, then a qualifying H2 round with a changed committed base accepts under the same campaign with four retained rounds. `CampaignManagerTest#test_history_survives_heads_restart_and_unresolved_high_absent_from_later_reviews` records H1/H2 rounds and proves the absent earlier High remains open despite convergence/current evidence. |
| SC2 | `test_partial_scope_restart_idempotence_conflict_and_missing_report` restarts manager reads, preserves partial coverage, counts completion once, rejects replay conflict and missing report. Store `test_atomic_roundtrip_restart_and_corruption` and `test_concurrent_mutations_serialize_without_lost_records` verify recovery and serialization. `test_missing_earlier_counted_report_blocks_acceptance_without_erasing_rounds` and `test_partial_attempt_and_earlier_approval_sources_remain_required_after_convergence` verify retained artifacts are required without erasing counters. |
| SC3 | `test_noop_failed_and_empty_attempts_never_count` checks no-op/failure/empty counters; partial scope test checks incomplete multi-module coverage; `test_partial_high_keeps_completed_round_nonclean_even_when_repaired_before_coverage_finishes` preserves non-clean history. Public CLI scenario executes empty pins and observes `recorded_complete: false`. `CampaignEvidenceTest#test_missing_execution_and_fabricated_approval_cannot_count_or_accept` rejects fabricated evidence. |
| SC4 | `test_contract_successor_retains_findings_and_same_contract_reuses_identity` changes head under the same contract, rejects policy rewrite and unreasoned contract change, and verifies a linked successor retains findings. Concurrent start test proves one subject/contract identity. |
| SC5 | `CampaignReceiptTest#test_campaign_consumption_uses_existing_authority_and_does_not_advance_candidate` uses actual managed assignment/attempt identities and accepted evidence-ref publication. `test_stale_snapshot_and_attribution_cannot_bypass_receipt_checks` rejects self-review, fabricated result identity and stale head. `test_read_only_check_evidence_recovers_from_journal_and_rejects_unknown_digest` reads accepted proof without cache/audit checkout creation or candidate HEAD changes. |
| SC6 | `test_pr_delta_collection_requires_exact_pinned_reference` rejects unpinned/different delta coverage. Public CLI scenario validates parseable JSON, quiet presentation, non-mutating dry-run, replay and restart. Command tests `test_help_dispatch_and_repeatable_review_options_remain_primary`, `test_unknown_malformed_campaign_and_finish_are_parseable_failures`, and `test_collection_binding_requires_pinned_scope_and_actual_repository_identity` cover additive dispatch, help, old flags, errors, wrong/narrow selectors and binding. Evidence tests check symlink escape, skipped/failed extraction, and removal of an inventoried finding. Public CLI rejects a nonexistent base for a files scope without recording attempts. PR status test uses the existing provider boundary and blocks unavailable/unsupported sources. |

## Implementation commits

- `4b4aa4ab3`: durable campaign storage and input contracts.
- `f8a53182b`: scoped rounds and current campaign acceptance.
- `2092c08ce`: assignment receipt consumption of campaign results.
- `7f0af2f3f`: retained evidence, scope subject pinning and accepted check authority.
- `caeef066b`: retain partial-attempt and historical approval sources in acceptance checks.
- `b67459ba5`: extraction inventories, local commit provenance and PR delta scope identity.
- `452696c6e`: full local coverage, exact diff provenance, post-finding approval and optional receipt digest shape.
- `b1f6b4314`: full PR manifest validation, durable supersession, unambiguous canonical assessments, immutable finding snapshots and verified earlier-source resolution.
- `b4186b246`: managed immutable review/check execution proofs, purpose-bound read authority, malformed policy rejection and latest committed local-base pins.
- `0ffe53d50`: reserved whole-PR scope, completed coverage after terminal blocker updates, and private-artifact workspace handling.
- `0c302c7a6`: all retained review authority, read-only historical proof, active contract reuse and authority-boundary controls.
- `477795cc0`: accepted assessment provenance, canonical blocker update gates, consistent reused dry-run output and boolean currency validity.
- `ee1873199`: current and retained independent approval authority through accepted ordinary review verdicts.
- `b863adff7`: normal empty seeded journal recovery and actual authority-loss fixture.
- `a95b75567`: partial blockers reset convergence across round IDs; PR provider failures emit blocked JSON.
- `bcb627d86`: canonical PR history identity, noncanonical stored-state rejection and nonempty real local full diffs.

## Formal campaign history and verified corrections

Frozen delivery policy requires at least three completed full rounds, the last two clean of verified High/Critical findings, no unresolved High/Critical, independent current-head approval and executed current-head test receipts. Contract identity: `c7cbf0f574ff6a8a52edabab6861f271c3ec645d2b7f2ed018bd739b62bed1da`.

| Collection | Lens and receipt | Outcome |
|---|---|---|
| r1 at `d4b2b3e01` | Whole-PR code-valid; `8x0vtj` | Zero findings; counted as historical collection, never approval. |
| r2 at `41971cfb4` | Whole-PR code-fit deep lens; `8x0vyf` | Medium `8x0w0x4y`: a stale report checksum let the approval negative pass too early. Fixed by refreshing/reaccepting report, extraction and metadata and requiring valid session evidence before approval-specific rejection. |
| r3 at `c4b911bcc` | Whole-PR code-valid; `8x0w2s` | Medium `8x0w60wd`: global successor lookup blocked status/finish with unrelated corruption. Fixed by using the checksummed successor marker and publishing it before the child; tests cover isolated acceptance and interrupted publication. |
| r4 at `f858b20a2` | Whole-PR code-valid; `8x0wd9` | Medium `8x0wggo0`: start/reuse conservatively validates the global identity registry. Initially retained as a fail-closed availability tradeoff; the later identity-index fix now isolates start/reuse without ignoring missing subject history. |
| audit-r4 at `f858b20a2` | Actual `ace-llm` query using the collector’s exact complete input; collection `8x0wle` | High `8x0wk9ip` and Medium `8x0wk9iq` verified. Source approval `8x0wep` is failed. The accepted rejected audit resets the clean streak to zero; it never grants approval. |

The audit found non-success model states could count completion and the separate runner-recorded head was not checked. Completion now requires explicit model success and recorded head equal to the pin. New negatives preserve genuine report inventories and reaccept all changed metadata; original source fails both at `review/8x0wn6`, repaired source passes 10 / 58 at `review/8x0wmz` and `review/8x0wnp`. Both findings are resolved through ACE feedback. Two fresh clean full rounds are required before final approval. Budget-rejected packets execute no models and count no rounds.

The obsolete delivery instruction named a nonexistent `code-deep` preset; the available `code-fit` covers architecture, security, performance and test quality. Formal collections execute actual `gpt-6-sol` reviews and actual feedback extraction. Deterministic integration fixtures separately validate the coordinator boundary and do not claim paid-provider readiness.

The later explicit approval audit at `32038575c` rejected first-record deletion: global scanning treated a missing first record as a new subject. Formal r7/r8 also found fetched PR head and local checkout head could disagree. Both verified High defects are repaired before final approval. A checksummed subject index is published before every new record, retained across deletions, validated on reads and used for subject-scoped reuse. It rejects missing indexed records, lost/corrupt indexes, unregistered identities and interrupted creation. Campaign PR collection requires local `HEAD` equal to fetched head before model execution; ordinary unbound PR collection retains its existing behavior.

Regression controls against previous production fail for first-record loss and checkout mismatch, including the real ReviewManager pipeline reaching the model incorrectly. Repaired targeted store/manager/command tests pass 41 tests / 322 assertions at `review/8x0xbl/report.md`; original production fails at `review/8x0xbd`. The pipeline negative confirms zero model calls for a mismatch and one successful ordinary unbound call. Fresh full rounds and exact-head suites remain the final acceptance authority. Formal rejected approval audits are retained as collections and never count as approvals.

## Delivery repairs and local releases

- Public assignment source-config archival rebuilt assignments without task/project attachment. Preserve both fields; regression tests persisted YAML attachment and explicit input precedence. Targeted 58 / 437 at `assign/8x0vre/report.md`.
- Docs bulk-update fixtures lost dropped `Tempfile.new` paths under garbage collection. Use `Tempfile.create` with directory-owned teardown; forced GC retains the original two-document count. Targeted 15 / 55 at `docs/8x0vwu/report.md`.
- macOS descendant cleanup signals can precede observable process exit. Tests now use a bounded monotonic wait for the same absence predicate; a live five-second child must fail a short wait. Product cleanup and timeout assertions are unchanged. Targeted 24 / 74 at `llm-providers-cli/8x0w8b/report.md`.

Prepared local releases: `ace-review 0.57.0`, `ace-assign 0.60.0`, dependency follower `ace-overseer 0.18.1`, fixture patches `ace-docs 0.34.5` and `ace-llm-providers-cli 0.36.1`. Package/root changelogs and lockfile are coordinated. Assignment requires review `~> 0.57`; overseer requires assignment `~> 0.60`. Retrospective: `.ace-retros/8x0vpa-t-ig2-review-campaign-delivery/8x0vpa-t-ig2-review-campaign-delivery.retro.md`.

No merge, deployment or RubyGems publication was performed. GitHub’s one approving-review rule is separate from local campaign approval; authenticated PR author `cs3b` cannot self-approve.

## Scope and recovery

Existing review/feedback entrypoints remain primary; campaign dispatch is additive. Whole-PR scopes require verified complete unfiltered diff manifests. Local full scopes require real nonempty committed diffs. Missing/corrupt/stale retained evidence fails closed; historical proof never becomes a current check. Canonical identities, supersession, replay conflicts and partial blocker observations cannot bypass convergence.

The frozen delivery rule is supported; discovery, caps/retries/escalation and new forge adapters remain separate work. Usage and schemas are in `ace-review/docs/campaigns.md`; the execution workflow is in `ace-review/handbook/workflow-instructions/review/pr.wf.md`. No compatibility fallback or migration was added.
