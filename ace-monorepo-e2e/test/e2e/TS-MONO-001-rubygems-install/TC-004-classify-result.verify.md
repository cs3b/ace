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
3. **Proof artifact exists** — `results/tc/04/proof.md` exists and contains:
   - Ruby version
   - Gem count
   - Classification
   - At least one evidence reference to install outcomes
4. **No invalid classification** — Classification is not blank, not a multi-word phrase, and not a value outside the three valid options.

## Verdict

- **PASS**: Valid classification that is consistent with TC-002/TC-003 evidence, proof artifact present with required fields.
- **FAIL**: Missing classification, inconsistent with evidence, or proof artifact missing/incomplete.

Report: `PASS` or `FAIL` with evidence (classification value, consistency check).
