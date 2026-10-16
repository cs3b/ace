# Code Review: Canonical Candidate Test Execution (7ed745fcd..1cb4010be)

## Summary

This change introduces the dynamic candidate-bound test path: a closed 4-field canonical candidate reference (`candidate_reference` RPC), a root-only candidate download (`command_candidate`), digest-bound installed Ruby test runtime profiles, root materialization into a sealed view, and merge-proof coupling of test evidence to the exact candidate reference. I verified the integration points against the repo (Router transfer registration, `socket_server.rb` download framing, `OrdinaryClient#scratch_root`, `CandidateTransfer#materialize_repository` signature, `RetainedInput.json` bounds, `GrantResolver.read_verified` semantics, json 2.21.2 / Ruby 3.4 for `allow_duplicate_key` / `Find(ignore_error:)`).

**Verdict: Approve with medium-severity follow-ups.** No Critical/High correctness breaks found in the guarded paths. The concurrency design (thread-bound views, scope-before-journal-CAS lock order, shared→exclusive promotion refusal) is careful and genuinely tested, including a real race test. The findings below are hygiene, failure-path cleanup, error-class consistency, and coverage gaps — several explicitly disclosed as OPEN in the plan document.

**Strengths**
- ✅ Lock-order discipline is explicit and tested: `with_command_scope` holds the lifecycle scope before journal CAS; the view re-resolves each current prefix without reacquiring lifecycle locks (`test_concurrent_candidate_change_refuses_admit_and_later_claim_without_reversed_locks` proves no deadlock and correct refusal on supersede).
- ✅ `command_candidate` is a true read: no journal mutation, claimed-phase-only, original-launcher-only, and the test asserts `ref_value` unchanged plus refusal for operator peers and post-bind state.
- ✅ Strict closed schemas end-to-end: policy `ordinary-candidate` source keys, exact reference shape (rejects caller `head`/`path` extras), runtime profile key/argv/placeholder contract, and 8 KiB compiled-definition bound — all with negative tests.
- ✅ Honest test scoping: the Linux-root fixture explicitly labels itself "no canonical proof", and `test_evidence_at!` now structurally prevents static probe receipts from satisfying ordinary merge.

---

## Deep Diff Analysis

**Findings (verified in the changed lines):**

| # | Severity | Location | Finding |
|---|----------|----------|---------|
| 1 | 🟠 Medium | `ace-assign/CHANGELOG.md`, `ace-lab/CHANGELOG.md` (absent from diff) | No CHANGELOG entries for substantive changes to both gems. Violates ADR-020 and the explicit DON'T in `docs/ace-gems.g.md` ("skip changelog updates"). Both files exist with `[Unreleased]` sections that were not extended. |
| 2 | 🟠 Medium | `ace-lab/lib/ace/lab/organisms/command_candidate_view.rb` (`prepare!`) | Failure after `Dir.mkdir(root)` (download Conflict, materialize rejection, seal failure) leaves a partially-populated view directory and permanently wedges the execution in `claimed` phase (no cancel/timeout transition exists for commands). Retry with the same `execution_id` is impossible by design (EXCL), so residue accumulates. |
| 3 | 🟠 Medium | `command_owner_admission.rb` `verify_context!` (`contained_alias = ... File.realpath(path)`); `command_candidate_view.rb` `seal` | Dangling symlinks make `File.realpath` raise raw `Errno::ENOENT` (`SystemCallError`) instead of the typed refusals used everywhere else (`InvalidConfigurationError`/`SecurityError`). Unreachable via the normal path (`CandidateTransfer#materialize` rejects dangling links first — verified), but this is the "dirty view refuses" defense line listed in the responsibility map, and `command_test_evidence!` only rescues `SecurityError, InvalidConfigurationError`, so the raw error would escape historical proof paths. |
| 4 | 🟠 Medium (test gap) | `command_owner_admission.rb` | The production admission's dynamic branches have no non-root coverage: `compile_selection`'s native-producer binding check, `command_candidate!`'s equality/`Conflict` paths, and `verify_context!`'s `dynamic && materialized` branch are only exercised indirectly. The reviews fixture uses a fake admission; the root probe bypasses `CommandOwnerAdmission` entirely (calls `policy.select` + `CommandTestRuntime` directly). Partially disclosed as OPEN in the plan, but these are mockable pure-composition paths. |
| 5 | 🟡 Low | `ordinary_review_evidence.rb:119-131` (`ordinary_candidate_reference`) | `with_candidate_reference` runs the full resolution — including `bounded_blob` (up to 64 MB) — before the inner `authorize!` re-check, although the response contains only the 4-field reference. Any project-authenticated peer can amplify journal/blob reads. (Transport auth at dispatch entry still gates access, so this is resource amplification, not exposure.) |
| 6 | 🟡 Low | `ace-lab/lib/ace/lab/cli/commands/run.rb:45-46` | Candidate-file read failures (`SystemCallError`: missing file, EACCES) map to `"usage_error: run requires unique project/executor options and literal argv after --"` — a misleading message that doesn't mention `--candidate`. |
| 7 | 🟡 Low | `command_execution.rb:66-67` vs `socket_server.rb:189-191` | The `command_candidate` branch computes a `TransferCodec` descriptor that the socket server immediately overwrites with its own descriptor built from `transfer_parts`. Pure duplication (same pure function, same bytes); keep only `transfer_parts`. |
| 8 | 🟡 Low | `ace-assign/test/feat/authority/command_execution_test.rb` (fake `Admission`) | The fake lacks `with_command_scope`; it works only because no definition in that fixture carries a `candidate` key. Adding one later fails with `NoMethodError` instead of a clear fixture error. |
| 9 | 🟡 Low | `command_owner_admission.rb` `verify_context!` (20_000-entry bound) | The Find bound now applies to the *entire materialized candidate tree* (work tree + materialized `.git`), where it previously bounded a small installed cwd. A full monorepo candidate can plausibly approach 20k entries; a legitimate candidate would then be refused with "command source exceeds verification bound". Ties directly to the still-OPEN installed acceptance gate. |

**Intent/impact per major change** — the reference/scope machinery in `ace-assign` composes correctly with the existing exclusion/journal CAS model (I traced `dispatch → with_command_scope → with_candidate_reference_scope → with_scope` and the merge path's already-held-scope shortcut; no inverted lock acquisition found). The `candidate_reference` nil-mutation/no-transfer contract is enforced at both client (`ordinary_assignment_client.rb`) and server. The `NotFound` (was `Conflict`) now raised for claim/bind/complete on unknown execution IDs is a benign, more truthful behavior change.

## Code Quality Assessment
- **Complexity**: `CommandOwnerAdmission` and `OrdinaryReviewEvidence` are now carrying substantial hidden state (`@candidate_views`, `@ordinary_scopes`) with thread/lock invariants; comments document the lock order well, but the class is approaching the point where the scope bookkeeping deserves its own molecule.
- **Maintainability**: `CommandTestRuntime` is a clean, data-only validator with deterministic `gemfile`/`configuration` output — byte-comparable in `verify_context!`, which is the right pattern. The `prepare!` organism correctly avoids evaluating any candidate code as root.
- **Test delta**: strong negative coverage on policy/runtime validation; see Finding 4 for the admission-layer gap.

## Architectural Analysis
- **Pattern compliance**: ATOM layering respected (`CommandTestRuntime` molecule, `CommandCandidateView` organism, scope state on the lifecycle). Router/TRANSFER_OPERATIONS extension follows the existing handler-registration contract (`const_defined?(:TRANSFER_OPERATIONS, false)` verified in `router.rb:32`).
- **Dependency changes**: `ace-lab` now requires `ace/assign/authority/retained_input` and `command_test_runtime`/`command_candidate_view` — both within the existing ace-assign dependency edge; no new gems.
- **Component boundaries**: the `candidate_owner: -> { lifecycle }` late-binding lambda in `ordinary_authority_composition.rb` correctly closes over the local; `candidate_owner` fails closed with `InvalidConfigurationError` if unset.

## Documentation Impact Assessment
- **Required updates**: CHANGELOGs for both gems (Finding 1). The new `candidate-test-view-plan.md` accurately matches the implemented contracts (I cross-checked the null-mutation/no-transfer claim, the claimed-phase download restriction, and the static-probe merge exclusion).
- **API changes**: new public read op `candidate_reference`, new download op `command_candidate`, new `--candidate` CLI flag — none breaking; `test_evidence_at!` gained an optional keyword (backward compatible).
- **No migration notes needed** (pre-1.0, ADR-024).

## Quality Assurance Requirements
- **Test scenarios needed**: (a) production `CommandOwnerAdmission#command_candidate!` — requester-liveness-expired and candidate-changed (`Conflict`) paths via a controlled fake lifecycle; (b) `compile_selection` agent/native-binding mismatch; (c) `verify_context!` materialized-config tamper (rewrite `runner.json`) refusal; (d) failure-path cleanup behavior for `prepare!` (see Finding 2).
- **Integration points**: the full owner→launcher-helper→download→materialize→bind chain remains only exercised on Linux root (disclosed OPEN); the non-root composition up to `CommandCandidateView` policy/runtime checks is testable today.
- **Performance/monitoring**: `verify_installed!` walks up to 100k entries × 8 gem paths and re-runs on every `command_request!` (admit ×2, claim, candidate, bind) and every historical proof; deadline-bounded and fail-closed, but the repeated bundle `bounded_blob` reads (Finding 5) and repeated walks will be the first thing to trip slow-disk deadlines — worth instrumenting when the installed acceptance lands.

## Security Review
- **Attack vectors**: no path found for requester-controlled head/path/bundle bytes to reach execution — the reference is closed-shape, resolved server-side, and `compile` derives everything from policy + journal state. The CLI's `RetainedInput.json` bounds size (16 KiB), rejects symlinks and duplicate keys. `exec` uses `unsetenv_others: true` with a policy-merged environment whose reserved-key list (`command_policy.rb` `RESERVED`/`env_key?`) blocks `RUBYOPT`/`GEM_*`/`BUNDLE_*`/`LD_*` injection; the runtime's own `TMPDIR`/`XDG_CACHE_HOME` conflict check in `compile` closes the one gap the reserved list leaves.
- **Data flow**: candidate bytes never transit non-root processes; scratch is root-owned 0700; output/tmp is chowned to the dropped executor only; `GIT_OPTIONAL_LOCKS=0` addition correctly prevents read-only git probes from attempting writes into the sealed 0555 tree.
- **Compliance**: secrets remain excluded (`secret_references` must be empty in the executor path — pre-existing check intact). Findings 3 and 5 are hardening items, not exposures.

## Refactoring Opportunities
- Extract the ordinary evidence-scope registry (`@ordinary_scope_mutex`/`@ordinary_scopes` + the three helpers) from `OrdinaryReviewEvidence` into a small molecule; it is now consumed by three modules and is the most invariant-heavy code in the diff.
- Add a scope-only variant of `with_candidate_reference` (resolve metadata, skip `bounded_blob`) for `ordinary_candidate_reference` (Finding 5).
- Centralize the "symlink containment" check (`File.realpath(...).start_with?(root + "/")` now appears in `verify_context!`, `seal`, and `verify_installed!`) with explicit `Errno::ENOENT → refuse` handling (Finding 3).

---

### Action Items
1. **[Medium]** Add `[Unreleased]` CHANGELOG entries to `ace-assign` and `ace-lab`.
2. **[Medium]** `CommandCandidateView#prepare!`: clean up the created `root` directory on any failure after `Dir.mkdir` (and consider documenting the new-execution-id recovery for a wedged `claimed` execution).
3. **[Medium]** Treat dangling symlinks as containment failures (rescue `Errno::ENOENT` around the `File.realpath` checks in `verify_context!` and `seal`) so the refusal is typed, not a raw `SystemCallError`.
4. **[Medium]** Add non-root tests for the production `CommandOwnerAdmission` dynamic branches (`command_candidate!`, `compile_selection` binding check, `verify_context!` materialized tamper).
5. **[Low]** Fix the `--candidate` file-read error message in `run.rb`; drop the duplicate descriptor in the `command_candidate` branch; reorder/skip blob resolution in `ordinary_candidate_reference`; add a guard comment (or method) for the missing `with_command_scope` in the `command_execution_test` fake.

*Future considerations (not action items):* re-evaluate the 20k-entry source-walk bound against real monorepo candidates when the installed acceptance pipeline lands; `GrantResolver.read_verified`'s "trusted authorization file" wording now mislabels runtime-profile/Gemfile read failures.