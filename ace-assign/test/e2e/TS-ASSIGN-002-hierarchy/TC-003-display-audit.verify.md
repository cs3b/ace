# Goal 3 — Display and Audit Trail Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Inspect CLI-visible status/step evidence under `results/tc/03/`.
3. Use copied step files as fallback evidence when needed.
4. Use debug evidence only as fallback.

### Tree Display
1. **Hierarchy shown** — full status evidence shows parent/child tree structure.
2. **Nested numbering shown** — nested step numbers (e.g., `010.01`, `010.02`, `020.01`) are visible.

### Audit Trail
3. **Child mutation evidence** — CLI/state evidence shows child insertion under expected parent.
4. **Injected sibling evidence** — CLI/state evidence shows injection after target and renumbering impact.
5. **Dynamic top-level evidence** — CLI/state evidence shows dynamic top-level insertion.
6. **Metadata fallback (if needed)** — copied step files confirm metadata fields (`added_by`, `parent`) when CLI evidence is insufficient.

## Verdict

- **PASS**: Hierarchy display and mutation/audit behavior are proven primarily by CLI-visible outcomes (with file fallback when needed).
- **FAIL**: Required display or audit outcomes are missing/contradictory.

Report: `PASS` or `FAIL` with evidence (status snapshots and any metadata citations).
