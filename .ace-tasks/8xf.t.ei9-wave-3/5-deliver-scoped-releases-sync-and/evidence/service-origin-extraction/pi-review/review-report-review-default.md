# Code Review: Protected origin boundary extraction (ace-assign)

**Scope reviewed:** `fixed_service_lifecycle.rb`, `endcap_service_context.rb`, `endcap_service_replay_test.rb`, CHANGELOG, plan/evidence docs. Verified against the repo: `FixedServiceLifecycle` has exactly one includer (`Endcap`), `active_origin` is defined once (`endcap.rb:250`), and `service_origin_fields!`/`service_origin_matches!` have no duplicate definitions across the 13 Endcap context files.

## deep_diff_analysis

### ✅ Extraction of origin match logic → `service_origin_matches!` (3 sites: `fixed_service_lifecycle.rb:125, 300, 489`)

- **Intent:** Move the triple-field protected-origin comparison (`worker_process_binding`, `launch_ticket`, `reservation_generation`) behind the boundary owner so future ordinary adapters supply their own canonical reference.
- **Impact:** Semantically equivalent to the removed chained `&&` comparisons. Verified edge cases: missing keys in `record` → `Hash#slice` omits them → key-set mismatch → raise (old: `nil == value` → raise); malformed `origin` → `KeyError` from `fetch` in both versions, and the `rescue KeyError → UnauthorizedIdentity` mapping in `authorize_service_update!` still applies. `Hash#==` is order-independent, so `slice(*expected.keys)` ordering is irrelevant.
- **Alternatives:** A default implementation in the shared module was considered (see refactoring section) — current single-includer state makes it optional.

### ✅ Origin field construction → `service_origin_fields!` (2 sites: `fixed_service_lifecycle.rb:222, 458`)

- **Intent:** Single source for the protected launch identity tuple; `service_claim_plan` now merges the whole hash, `workspace_prune_preview_context_at!` fetches one field.
- **Impact:** Produces the identical three keys/values previously inlined; `SERVICE_IDENTITY` slice comparisons and the `claim_binding` digest inputs are unchanged. The leading-dot `.merge(...)` continuation is valid and consistent with file style.

### ℹ️ Preview path now fetches the full origin shape (`fixed_service_lifecycle.rb:222`) — **Low**

Old code fetched only `process_binding.process_identity`; `service_origin_fields!` also fetches `launch_ticket` and `reservation_generation`. This tightens the preview contract: an origin lacking those fields would now raise `KeyError`. Safe today because `active_origin` (`endcap.rb:250`) returns a bound/issued launch whose shape already supplies all three fields to the other paths — but this is the one spot that is behavior-*changing* rather than behavior-*preserving* in a degenerate-input sense. The plan document states the new adapter contract explicitly, so this is informational; no action needed unless you want the preview comment to mention the full-shape requirement.

### ✅ New test `test_authorization_read_rejects_each_changed_protected_launch_origin_without_effect`

Well-constructed: mutates each origin field independently, asserts `UnauthorizedIdentity`, asserts `journal.ref_value` unchanged after each attempt, and the `prepare!` canary proves check ordering (origin verified *before* fresh policy preparation). Positive case is covered by the adjacent existing test.

## code_quality_assessment

- **Complexity:** Net reduction — three duplicated comparison blocks collapse into one owner-owned method; no new branching added.
- **Maintainability:** Improved. The five call sites in the shared lifecycle now read as policy intent ("origin must match") rather than field-by-field plumbing.
- **Test coverage delta:** +1 test (9 assertions per evidence), targeting the exact semantic the refactor must preserve. All 23 feat tests, 24 organism tests pass per committed evidence.

*No issues found beyond the informational note above.*

## architectural_analysis

- **Pattern compliance:** Follows the established template-method seam already used in this composition (`service_scope_open!`, `service_origin!`, `service_worker!` delegate to the including owner). Consistent.
- **Dependency changes:** None — module-internal, no new gems/requires.
- **Component boundaries:** Correct direction — the protected Endcap keeps manufacturing the launch fields; the shared module never constructs them. Matches the plan's stated constraint ("no ordinary service admission enabled").

*No issues found.*

## documentation_impact_assessment

- ✅ CHANGELOG `### Changed` entry added (Keep a Changelog format, ADR-020 compliant) and accurately describes the refactor.
- ✅ Plan document updated with the adapter contract for the next ordinary boundary owner.
- 💡 **Low (Suggestion):** The hook contract ("implementers must define `service_origin_fields!`/`service_origin_matches!`; must not manufacture protected launch fields") lives only in the plan doc. A one-line comment above the two hook call sites in `FixedServiceLifecycle` (matching the existing comment style at `service_settlement_evidence!`/`authorize_service_update!`) would make the contract discoverable at the seam itself when the second adapter lands.

No API or migration impact (pre-1.0, ADR-024).

## quality_assurance_requirements

- ✅ Evidence committed: feat suite (23 tests), organism composition suite (24 tests), targeted changed-origin run, `checks.json` with `"production_changes": false`.
- 💡 **Low (Suggestion):** The changed-origin test covers the authorization-read path only; `service_begin_plan` and `service_claim_plan` exercise the same hook indirectly through existing tests. If you want direct per-path negative coverage for the hook, one begin_dispatch variant with a mutated origin would close that gap. Not blocking — the hook is shared, so the equivalence argument holds.

## security_review

- **Attack vectors:** No new ones. The extraction cannot weaken the origin check — `service_origin_matches!` compares the same three fields with `fetch` (fail-closed on malformed origin), and the new test proves each field independently rejects with no journal mutation before policy preparation.
- **Data flow:** No new data leaves the boundary; `service_origin_fields!` output feeds the same digests/binding as before.
- **Compliance:** n/a.

*No issues found.*

## refactoring_opportunities

- 💡 **Low (Future consideration, not an action item):** When a second (ordinary) adapter includes `FixedServiceLifecycle`, consider whether the module should declare the hook contract in-code (comment or minimal guard) — today, with a single includer, adding scaffolding would be speculative per repo principles.
- Note (out of scope): `.ace-tasks/.../evidence/` artifacts and the plan-doc additions are task bookkeeping, reviewed as intentional, not flagged.

---

**Verdict:** ✅ Clean, behavior-preserving boundary extraction. All five call sites verified equivalent (including missing-key and `KeyError` propagation semantics); single-includer status confirmed; test proves per-field rejection with immutability and ordering guarantees. Only informational/low suggestions — nothing blocking merge.