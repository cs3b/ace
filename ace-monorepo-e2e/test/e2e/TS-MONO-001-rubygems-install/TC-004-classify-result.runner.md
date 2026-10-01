# Goal 4 — Classify Installation Result and Verify Exact Versions

## Goal

Based on the outcomes from Goal 2 (normal install) and Goal 3 (full-index
fallback), classify the installation result, run the machine-readable
exact-version acceptance against the frozen release manifest, and produce a
proof artifact. Classification, exact-version acceptance, and scenario
completion are separate results: a `SAFE` classification alone never proves
the released graph, and a wrapper ERROR means the scenario is incomplete even
when every bundle exit was zero.

## Workspace

Save all output to `results/tc/04/`.

## Classification Contract

| Normal install | Full-index install | Classification |
|---|---|---|
| Exit 0 | (any) | `SAFE` |
| Non-zero | Exit 0 | `LAG_DETECTED` |
| Non-zero | Non-zero | `METADATA_BROKEN` |

## Steps

1. Read the exit codes from `results/tc/02/install.exit` and `results/tc/03/fullindex.exit`.
2. Apply the classification contract above.
3. Write the classification (exactly one of: `SAFE`, `LAG_DETECTED`, `METADATA_BROKEN`) to `results/tc/04/classification.txt`.
4. Run the deterministic exact-version acceptance. This compares every
   manifest entry from `results/tc/01/release-manifest.json` against both
   modes' lockfiles, activated-version receipts, and consumer-only
   dependency-edge resolutions:
```bash
proof_ruby_root="${ACE_E2E_SANDBOX_RUBY_ROOT:?}"
receipt_script="$PWD/ace-monorepo-e2e/test/e2e/TS-MONO-001-rubygems-install/install_receipt.rb"
LANG="${ACE_E2E_LANG:-C.UTF-8}" "$proof_ruby_root/bin/ruby" "$receipt_script" verify \
  --manifest results/tc/01/release-manifest.json \
  --normal results/tc/02 \
  --full-index results/tc/03 \
  --out results/tc/04/exact-version-acceptance.json
```
   Run this step regardless of the install outcomes: rejection findings are
   evidence, not failures of the goal.
5. Write a proof artifact to `results/tc/04/proof.md` containing:
   - Date/time of verification
   - Ruby version (`ruby -v`)
   - Gem count (from `results/tc/01/gem-count.txt`)
   - Normal install exit code and key evidence
   - Full-index install exit code and key evidence
   - Final classification
   - Exact-version acceptance outcome (the `acceptance` value and finding
     count from `results/tc/04/exact-version-acceptance.json`)
   - Operator guidance statement
6. Record the finalize contract: the final machine-readable verdict combines
   this acceptance artifact with the pipeline completion gate and is produced
   by `install_receipt.rb finalize` after the run completes (it reads the
   report `metadata.yml`, which only exists once the runner session has
   finished). The runner's job here is to leave the finalize inputs intact:
   `results/tc/01/release-manifest.json`, both mode directories, and
   `results/tc/04/exact-version-acceptance.json`.

## Constraints

- Do not collapse `LAG_DETECTED` and `METADATA_BROKEN` into one generic failure.
- If the distinction is unclear from evidence, classify as `METADATA_BROKEN`.
- Do not claim onboarding-safe status unless classification is `SAFE`.
- Do not claim exact-version acceptance unless `results/tc/04/exact-version-acceptance.json`
  records `acceptance: "pass"` with no findings.
- The classification file must contain exactly one word on one line.
- Never edit the acceptance JSON by hand; rerun the receipt script instead.
