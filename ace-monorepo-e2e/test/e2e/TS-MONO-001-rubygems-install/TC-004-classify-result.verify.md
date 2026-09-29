# Goal 4 — Classification Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Classification exists** — `results/tc/04/classification.txt` exists and contains exactly one of: `SAFE`, `LAG_DETECTED`, `METADATA_BROKEN`.
2. **Classification is consistent** — Cross-check with TC-002 and TC-003 exit codes:
   - If TC-002 exit is `0` → classification must be `SAFE`
   - If TC-002 exit is non-zero and TC-003 exit is `0` → classification must be `LAG_DETECTED`
   - If both are non-zero → classification must be `METADATA_BROKEN`
3. **Exact-version acceptance ran** — `results/tc/04/exact-version-acceptance.json` exists, parses as JSON with `schema_version: 1` and `kind: "exact-version-acceptance"`, records a `manifest` with a nonempty `package_count`, and covers both modes (`normal`, `full_index`) plus `consumer_edges` for `ace-bundle`, `ace-review`, and `ace-task`.
4. **Acceptance agrees with the raw goals** — The acceptance JSON's per-mode package states must agree with the lockfiles and receipts:
   - when both install exits are `0` and `acceptance` is `"pass"`, no package state may carry findings and both consumer edge sets must be `ok`,
   - when any finding exists, `acceptance` must be `"fail"` and the findings must cite the failing packages (name, manifest version, observed version) — a `"fail"` with empty findings, or a `"pass"` while a receipt/lockfile is missing, is a contradiction and fails this goal,
   - superseded versions recorded in the manifest must not appear in any lockfile or activated receipt.
5. **Proof artifact exists** — `results/tc/04/proof.md` exists and contains:
   - Ruby version
   - Gem count
   - Classification
   - Exact-version acceptance outcome
   - At least one evidence reference to install outcomes
6. **No invalid classification** — Classification is not blank, not a multi-word phrase, and not a value outside the three valid options.

Registry classification (step 1–2), exact-version acceptance (steps 3–4), and
final scenario completion are separate results. A `SAFE` classification with a
failed acceptance does not prove the released dependency graph, and a wrapper
ERROR means the scenario is incomplete regardless of any exit code.

## Verdict

- **PASS**: Valid classification consistent with TC-002/TC-003 evidence, a complete acceptance artifact whose verdict agrees with the raw receipts, and a proof artifact with required fields.
- **FAIL**: Missing classification, inconsistent classification, missing or self-contradictory acceptance evidence, or proof artifact missing/incomplete.

Report: `PASS` or `FAIL` with evidence (classification value, acceptance outcome, consistency check).
