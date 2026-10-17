# Code Review: Candidate Test View — Historical Proof, Entry Bounds, Failure Cleanup (1cb4010be..2b0925d85)

## Summary

This increment is the review-remediation + historical-reader cut of the candidate test-view work: a source-only `historical: true` test-proof mode, pre-materialization source-entry bounding (`max_entries` with ancestor counting), fresh-view failure cleanup with dev/inode identity checks, typed classification of filesystem observation errors, a compile-time argv bound, the `HERDR_PANE` correction, CHANGELOG entries, retained review evidence, and a new production-admission integration test.

I verified the load-bearing contracts against the repo: no wire surface exposes `historical` (all wire handlers — `merge_evidence`, `candidate_reference`, command dispatch — call `test_evidence_at!`/`compile_selection` without it; only in-process Ruby consumers can opt in), merge stays latest-only (`ordinary_merge_evidence.rb` `merge_evidence_at!`), the view pins its mode (`CandidateReferenceView#read!` requires `historical == @historical`), and all requires in the new test files resolve through the existing load chain (`open3` via `prepared_registration_fixture`, `timeout` via `transfer_codec`/`bounded_process`, `securerandom` via `lifecycle_exclusion`, `etc` via `execution_identity_resolver`, `socket` via `ordinary_peer`).

**Verdict: Approve.** No Critical or High findings. Every prior-round action item (CHANGELOGs, failure cleanup, error classification, admission coverage, entry bound, argv bound) is addressed or explicitly dispositioned. Remaining items are Low severity — classification precision, minor inefficiencies, and test hygiene.

**Strengths**
- ✅ Historical mode is genuinely source-only and mode-pinned: a historical scope cannot serve current admissions (integration test asserts `EvidenceUnavailable`), current paths never opt in, and historical resolution still enforces `producer_origin == origin_at!` at the current prefix, `recorded_binding!` liveness, and — newly strengthened for **both** modes — bundle byte size + SHA256 verification before returning bytes.
- ✅ `max_entries` preflight is correct and cheap: the inventory `Set` counts files plus ancestor directories (root `""` included), is checked *before any source file writes*, and its 20,000 semantics align exactly with `verify_context!`'s source bucket (both count the root), with `.git` admin split into its own 1,000 budget. The boundary test (3 refuses / 4 accepts, cleanup asserted) pins the semantics.
- ✅ `prepare!` failure hygiene is well-designed: EXCL `mkdir` with typed `EEXIST` refusal, `prepared` flag, and an ensure-block that re-stats dev/inode/uid/symlink before `remove_entry_secure` — only a provably-own fresh pre-child view is removed; the probe proves the refusal/preservation/removal triad.
- ✅ The new `command_owner_candidate_integration_test.rb` closes the prior coverage gap honestly: real journal/registration/start/transfer/Unix-peer I/O with named, confined projection boundaries (`InstalledStat`, launcher stub), covering supersede, tampered/unlinked config, grant revocation, native revocation, and the "historical must not probe the dead requester CLI" property via a `live!` flunk stub.

---

## Deep Diff Analysis

**Findings (verified in the changed lines):**

| # | Severity | Location | Finding |
|---|----------|----------|---------|
| 1 | 🟡 Low | `ace-lab/lib/ace/lab/organisms/command_candidate_view.rb:69-70` (rescue spanning `yield scratch` at 45-47) | `rescue SystemCallError → SecurityError "candidate view is not fully observable"` encloses the download block. In production (`command_executor.rb:44-47`) the block drives `OrdinaryClient#call`, which already normalizes transport `SystemCallError`/`IOError` to `EvidenceUnavailable` (`ordinary_client.rb:64-65`), so practical exposure is limited to genuine scratch/filesystem errors — but any `SystemCallError` escaping the client would be mislabeled as a filesystem-security refusal. Narrow the rescue to the filesystem steps or document the pre-normalization invariant. |
| 2 | 🟡 Low | `ace-lab/lib/ace/lab/molecules/command_owner_admission.rb:227-229` | `File.join(source_root, ".git")` is recomputed twice per `Find` entry — up to ~42k string allocations per verification, and `verify_context!` runs on every admit (×2), claim, bind, candidate, and evidence read. Hoist it above the block. |
| 3 | 🟡 Low | `ace-assign/lib/ace/assign/authority/ordinary_review_evidence.rb:64-68, 78` | A historical digest that never existed raises `Conflict "canonical candidate reference was replaced"` — misleading for an unknown (vs. superseded) reference. Cosmetic, but distinct messages would aid campaign-consumer diagnosis. |
| 4 | 🟡 Low | `ace-lab/lib/ace/lab/cli/commands/run.rb:59-61` | Outstanding from the prior round: `--candidate` file-read failures (`RetainedInput.json` → `SystemCallError`) still surface as `"usage_error: run requires unique project/executor options and literal argv after --"`, which doesn't mention `--candidate`. Not changed by this diff (only `HERDR_PANE` was touched here). |
| 5 | 🟡 Low | `ace-lab/lib/ace/lab/molecules/command_owner_admission.rb:115-117` | The broad `rescue SecurityError, InvalidConfigurationError → ReceiptRejected` also converts scope-infrastructure failures ("nested command candidate scope", "canonical candidate owner is unavailable") into "policy or source is unavailable" — a programming bug reads as policy revocation. Consider letting infrastructure `SecurityError`s surface distinctly. |
| 6 | 🟡 Low | `ace-assign/test/support/ordinary_native_observation.rb:6` | The shared class body is indented six spaces inside two flat modules. Now consumed by two gems' suites; worth fixing for readability. |
| 7 | 🟡 Low (test hygiene) | `ace-lab/test/feat/command_owner_candidate_integration_test.rb:214` | `assert thread.join(3), "canonical owner must drain"` inside `ensure` can mask the primary failure with a secondary assertion error. Prefer logging/collecting the join result in teardown. |

**Intent/impact per major change:**
- **Historical reader** (`ordinary_review_evidence.rb`, `command_execution.rb`, `command_owner_admission.rb`): the historical branch validates the digest-addressed `submit_candidate` event's `candidate_generation`, `producer_origin` equality with the *current* canonical origin, head/tree SHA-40 shape, sha256/bytes bounds, then slices the same six keys the current path returns — shape parity with `candidate_at!` holds (`bundle_ref` is unvalidated in both paths, going straight to `bounded_blob`; journal events are owner-written, so no new gap). `compile_selection(evidence: true)` replaces the live `identity!` pane probe with the retained `native_binding` compared against the canonical origin — exactly the documented "outlives its requester" contract; a nil `retained_native` for an agent kind fails closed via the origin-equality check.
- **Entry bounds** (`candidate_transfer.rb`, `command_policy.rb`, `command_candidate_view.rb`, `verify_context!`): `ArgumentError` guard on invalid bounds, inventory built from `ls-tree -z` paths (tab-split is safe; NUL-separated paths can't contain the separator), `reject!` mid-loop before writes, and `materialize_repository` threads the bound through. `verify_context!`'s two-bucket `Hash.new(0)` keyed on the git-admin boolean is correct (the `.git` dir itself lands in the admin bucket).
- **Failure cleanup** (`command_candidate_view.rb`): the ensure-block's identity re-check (`directory? && !symlink? && uid.zero? && dev/ino` match) is a sound TOCTOU defense; raising "identity is uncertain" from `ensure` intentionally masks the original error only in that ambiguous case (fail-closed, documented in disposition). `remove_entry_secure` on the sealed/executor-chowned tree is root-safe.
- **`HERDR_PANE`** (`run.rb:51` + test): correct variable per Herdr; the only remaining `HERDR_PANE_ID` reference is the test proving it's ignored.
- **Evidence artifacts**: internally consistent (`report_sha256` ↔ `sha256.json` ↔ `llm_metadata.yml` prompt hashes all cross-match in the committed text; heads `5488862bc`/`1cb4010be` match report titles). Byte-level SHA recomputation was not performed in this review (no execution); the disposition's "neither reviewer executed tests" claim is consistent with the metadata.

**Out-of-scope observations (pre-existing, explicitly dispositioned):** the duplicate transfer descriptor in the `command_candidate` branch (`command_execution.rb:66-67` vs `socket_server.rb:189-191` — retained per disposition); `ordinary_candidate_reference` resolving + now hashing the full bundle before `authorize!` (amplification unchanged; disposition declined removal); `GrantResolver#verify_error` labeling runtime-profile/Gemfile read failures as "trusted authorization file" issues.

---

## Code Quality Assessment
- **Complexity**: `verify_context!` remains the cognitive-load hotspot (three modes × two entry budgets × config/executable/git checks), but the new bucket split is a net simplification of the bound semantics. `resolve_candidate_reference!`'s historical/current branch is well-guarded and mirrors `candidate_at!`'s shape closely.
- **Maintainability**: constants centralized in `CommandPolicy` and consumed by both the molecule and the organism — good single source. The shared `OrdinaryNativeObservation` fake removes 30 lines of duplication across two gems' suites.
- **Test coverage delta**: strongly positive and targeted — boundary test for the entry bound, historical-proof lifecycle (positive, stale-current refusal, wrong-reference refusal, revoked-origin refusal), compile-time argv refusal, `HERDR_PANE` hint, kernel-probe cleanup assertions, and the full production-admission integration pair. No coverage removals detected.

## Architectural Analysis
- **Pattern compliance**: ATOM layering respected — bound logic inside the `CandidateTransfer` molecule, budgets as policy constants, cleanup in the `CommandCandidateView` organism; flat test placement followed (`test/feat/`, `test/support/`).
- **Dependency changes**: none new; the ace-lab→ace-assign test-support relative require follows the existing `prepared_registration_fixture` pattern.
- **Component boundaries**: the historical flag threads through four layers (execution → admission → scope → view) with validation at each entry point (`ArgumentError` guards at `test_evidence_at!` and `with_candidate_reference_scope`); no wire leakage.

## Documentation Impact Assessment
- **Required updates**: CHANGELOG entries added to both gems under `[Unreleased]` ✅ (prior finding closed). Version bumps deliberately deferred to the coordinated final cut per the disposition — a documented deviation from ADR-020's bump guidance, acceptable as a stated decision. The plan document now matches the implemented contracts (I cross-checked the no-wire-flag, latest-only merge, 20k/1k budgets, 2,048-byte argv bound, and cleanup scope claims against the code).
- **API changes**: additive optional keywords only (`historical:`, `max_entries:`); no breaking changes in this cut.
- **No migration notes** (pre-1.0, ADR-024).

## Quality Assurance Requirements
- **Test scenarios to consider**: (a) historical proof after the producing attempt leaves the `running` state (currently `origin_at!` requires `running: true` — intentional per plan, but a test pinning that refusal would document the boundary); (b) a `command_candidate` download whose client raises a raw `SystemCallError` (Finding 1's classification); (c) `.git` admin exceeding 1,000 entries (packed-vs-loose object layout) — plausibly covered by the installed acceptance gate that remains OPEN.
- **Integration points**: the installed root pipeline (real distinct UIDs, launcher ancestry, labd/helper composition) remains honestly OPEN per the plan and disposition; the Linux kernel probe and this host fixture cover the source-only composition.
- **Performance to monitor**: the current-path resolution reads + hashes the ≤64 MB bundle up to three times per call (`candidate_reference_at!` → `candidate_at!`, `candidate_at!` again, final `bounded_blob` + new digest check) — this diff added a hash pass, not a read. With resolutions at admit×2/claim/bind/candidate/evidence, instrument bundle-read counts when the installed acceptance lands; `verify_installed!`'s ≤8×100k walk also re-runs per stage (deadline-bounded, fail-closed).

## Security Review
- **Attack vectors**: no new exposure found. The historical path cannot be reached from the wire; digest addressing plus `producer_origin == current origin` plus `recorded_binding!` prevents replaying a revoked/rebound producer's old proof; mode pinning prevents a historical scope substituting for current admission. The new byte-digest check closes the previously unverified `bounded_blob` return in both modes.
- **Data flow**: unchanged — candidate bytes still transit only the authenticated owner socket into root-private scratch; cleanup removes only dev/inode-verified fresh views; accepted journal bytes are never deleted by this path.
- **Compliance**: findings 1 and 5 are classification-precision items on failure paths, not exposures; all refusals remain fail-closed.

## Refactoring Opportunities
- Hoist the `.git` prefix computation out of the `Find` loop (Finding 2); consider extracting `verify_context!`'s three modes into named private methods (`verify_static_source!`, `verify_materialized_source!`, `verify_runtime_config!`) — carried over as a future consideration from the prior round.
- Distinguish infrastructure `SecurityError`s from policy mismatches in `command_test_evidence!`'s rescue (Finding 5).
- Fix the shared support file's indentation (Finding 6).

---

### Action Items
1. **[Low]** `CommandCandidateView#prepare!`: narrow the `SystemCallError` rescue so download-block errors can't be mislabeled as filesystem-observability failures (or assert/document the client's pre-normalization invariant with a test).
2. **[Low]** `verify_context!`: hoist `File.join(source_root, ".git")` out of the `Find` block.
3. **[Low]** Distinguish "historical reference unknown" from "replaced" in `resolve_candidate_reference!`.
4. **[Low]** `run.rb`: give `--candidate` file-read failures a message that names `--candidate` (outstanding from prior round).
5. **[Low]** Test hygiene: avoid `assert` in the integration fixture's `ensure`; fix `ordinary_native_observation.rb` indentation.

*Future considerations (not action items):* bundle-read count instrumentation for multi-pass resolutions; re-evaluating the 1,000-entry `.git` admin budget against real packed layouts when the installed acceptance pipeline lands; `GrantResolver`'s "trusted authorization file" wording for non-grant read sites.

✅ **Verdict**: Approve. All items are non-blocking hardening; the prior round's action items are faithfully closed and the OPEN boundaries (installed pipeline, maintained runtime packaging, publication, taskless secrets) are truthfully labeled rather than papered over.