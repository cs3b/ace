# Independent Read-Only Source Review — Hermes Delta

**HEAD:** `1ec8e5913e7d3313459ef372d02551623e24e245` (base `c1e9fe02bfaad37974d6e070129d360e5f25b125`)
**Provider/Model:** pi:zai/glm-5.3:high@ro (exact configured; no fallback used or offered)
**Scope:** Complete `.ace-local/ei9-review/hermes-delta-packet.md` — 15-path SHA256 manifest + full untruncated diff; current owning files read in full: `relay.rb` (597 lines), `poller.rb`, `registry.rb`, `runtime.rb`, `molecules/hermes_atomic_writer.rb`, `test/fast/transport/multi_project_relay_test.rb` (full), plus repo-wide greps for `runtime/v1`, `ace.hitl.hermes.runtime/`, and all `warn`/`.message` logging surfaces.

## Checks actually performed by this reviewer
Read-only: packet-vs-manifest completeness (15/15 paths present in diff), diff-vs-current-file consistency, source-level verification of each disposition, regression coverage mapping, closed-table/logging-surface audit. **No tests executed by me** (read-only model per brief); author-reported executions: focused 23/136 PASS, full Hermes 192/1115 PASS (`5f76f0e5-b9a3-4417-9652-3c7093b73db8`), HITL proposal real-socket 28/186 PASS (`8d6cf319-ce36-4fe7-a619-0428c6421bad`), `git diff --check` PASS. No source edits, no mutations, no messages sent.

## Findings per feedback item

**26 M1 — typed static diagnostics: PASS.** `IngressUnavailable` now carries a closed 5-entry `REASONS` table; `initialize` uses `REASONS.fetch` (unknown reason → KeyError, fail-closed). All 5 raise sites use symbol keys; message strings are byte-identical to the prior literals, so typed specificity is preserved. `poller.rb:84` and `relay.rb:229` warn `error.message` only `if error.instance_of?(IngressUnavailable)` — static text only. `persist_ingress` has `rescue IngressUnavailable; raise` precedence before the `:persistence_failed` wrap, so Ruby's automatic `cause` retains the raw lower exception in-process without logging it (regression asserts `IOError` cause retained, warning contains typed message, excludes `"987654"`/`"private OTP"`). Other logging surfaces stay class-only (`runtime.rb:66`) or raise-only. Poller's re-raise is a static ContractError. M1 nuance satisfied exactly.

**27 M2 — fail-closed missing body: PASS.** `retained_ingress` raises `:body_unavailable` on missing/edited (digest mismatch); drain marks `unresolved` and blocks only that `[channel, project]` scope — no age-based unblock, no reconstruction, no abandonment path exists in source. Exact-backup/restore procedure documented in `usage.md` (identity, sequence, digest, mode 0640, atomic writer, no journal surgery/offset reset); regression `test_missing_retained_body_stays_blocked_until_exact_backup_is_restored` exercises actual unlink → blocked → exact-byte restore → exactly-one delivery.

**28 L1 — hardened directory fsync: PASS.** `ingress_box` calls `Molecules::HermesAtomicWriter.sync_directory` (contract verify + `RDONLY|NOFOLLOW` + stat check + fsync) unconditionally after mkdir/EEXIST, so the existing-directory recovery path also gets the parent barrier (covering mkdir-then-crash). `cleanup_ingress` uses the same helper; both raw `File.open { fsync }` sites removed.

**29 L2 — Captain allowlist as set: PASS.** Registry admission normalizes `captain_user_ids` via `uniq.sort` before the frozen copy; both `route_identity` and `ingress_identity` slice the admitted representation. `canonical` sorts hash keys but never arrays, so `request_contexts` ordering stays significant — asserted by the regression.

**2a L3 — runtime/v2 mandatory: PASS.** `runtime.rb:25` requires `runtime/v2`; `hitl_socket` absent from `fields` so old configs fail on schema and unknown keys, without rewriting. Negative regression verifies refusal + byte preservation. Repo-wide grep: all live references are v2 (7 fixtures incl. `installed_proposal/consumer.rb` and `proposal_lifecycle_test.rb`); remaining `runtime/v1` occurrences are the docs refusal paragraph and the negative test only.

**2c L5 — actual deliver counter: PASS.** Fake `Lifecycle#deliver` increments `@deliveries` unconditionally while keeping the idempotent answer projection; crash/restart regression asserts `deliveries == 1`.

**2d — no folder recreation: PASS.** `cleanup_ingress` computes the scoped path and returns `unless File.exist?(path)` before `ingress_box` (which contains the mkdir). Regression removes the empty `.ingress`, drains, asserts non-recreation and no redelivery.

**2b / 2e — intentionally skipped (root-owned / by design):** confirmed absent from the delta; root CHANGELOG untouched (not in manifest); lazy storage barrier before offset acknowledgment remains verified by the existing fsync-probe tests (`assert_ingress_barrier_before_receipt`).

## Non-blocking observations
1. A persistently blocked retained body re-warns its static typed message on every drain/poll cycle (serve loop is 1s) — operationally noisy but exactly what "only exact typed message logged" implies; no action required.
2. `HermesAtomicWriter.write` raises `CollisionError` if the file exists — correct for the documented restore path (no overwrite of a conflicting file).

## Constraints honored
No abandonment protocol, no journal editing, no publication/deployment/version bump in the delta. Prior findings and operator-approval history preserved (packet references feedback `8xfsqo26`–`8xfsqo2e`; nothing erased). All-group/mTLS domain installation remains **OPEN**.

## VERDICT: **APPROVE**