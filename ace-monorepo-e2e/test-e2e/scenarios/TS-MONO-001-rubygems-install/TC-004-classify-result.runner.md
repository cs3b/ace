# Goal 4 — Classify Installation Result

## Goal

Based on the outcomes from Goal 2 (normal install) and Goal 3 (full-index fallback), classify the installation result and produce a proof artifact.

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
4. Write a proof artifact to `results/tc/04/proof.md` containing:
   - Date/time of verification
   - Ruby version (`ruby -v`)
   - Gem count (from `results/tc/01/gem-count.txt`)
   - Normal install exit code and key evidence
   - Full-index install exit code and key evidence
   - Final classification
   - Operator guidance statement

## Constraints

- Do not collapse `LAG_DETECTED` and `METADATA_BROKEN` into one generic failure.
- If the distinction is unclear from evidence, classify as `METADATA_BROKEN`.
- Do not claim onboarding-safe status unless classification is `SAFE`.
- The classification file must contain exactly one word on one line.
