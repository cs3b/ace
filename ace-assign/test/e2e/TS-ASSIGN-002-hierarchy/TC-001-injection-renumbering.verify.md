# Goal 1 — Injection and Renumbering Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm status/artifact evidence under `results/tc/01/`.
3. Use debug evidence only as fallback.

1. **Children created** — evidence shows children under `010` with expected nested numbering.
2. **Sibling renumbering** — evidence shows sibling insertion changed sibling numbering as expected.
3. **Grandchild placement** — evidence shows grandchild under the renumbered branch before second shift.
4. **Cascade renumbering** — final evidence shows both parent renumber and descendant renumber alignment.

## Verdict

- **PASS**: Injection and cascade renumbering behavior are proven by status outcomes.
- **FAIL**: Numbering transitions are missing, inconsistent, or incorrect.

Report: `PASS` or `FAIL` with evidence (step-number snapshots and metadata).
