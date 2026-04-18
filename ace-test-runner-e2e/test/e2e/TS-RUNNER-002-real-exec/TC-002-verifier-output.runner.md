# Goal 2 - Verifier Pass Produces Independent Verifier Output

## Goal

Confirm that verifier output artifacts are present and independent from runner-only
captures for the same report directory.

## Workspace

Save artifacts to `results/tc/02/`.

Capture:
- `results/tc/02/report_tree.txt` from listing `.ace-local/test-e2e/runner-002-report/`
- `results/tc/02/verifier_hits.txt` from listing report-tree file paths whose names demonstrate verifier-produced or verifier-consumed output under the report tree

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
- Do not write outside the sandbox.
- Populate `verifier_hits.txt` by listing matching file paths under `.ace-local/test-e2e/runner-002-report/`; do not grep file contents.
- The file-path match for `verifier_hits.txt` should include report outputs such as `summary.r.md`, `report.md`, `metadata.yml`, and any verifier-specific files when present.
