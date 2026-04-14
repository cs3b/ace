# Goal 3 — Display and Audit Trail Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Inspect copied canonical step files under `results/tc/03/step-files/`.
3. Use runner observations to locate the audit assignment when needed.
4. Confirm explicit command captures under `results/tc/03/`.
4. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
### Tree Display
1. **All steps shown** — `status_full.stdout` should show the hierarchy for both parents with nested children. Missing one optional child label is not an automatic failure if numbering/tree structure and other hierarchy entries are present.
2. **Hierarchy indicators** — Status uses tree characters (pipe |, tee, elbow, or similar hierarchy markers).
3. **Nested numbers** — Status shows nested step numbers 010.01, 010.02, 020.01.

### Audit Trail
4. **Child audit** — the copied child step file under `results/tc/03/step-files/` shows `added_by: child_of:010` and `parent: "010"`.
5. **Injection audit** — the copied injected sibling step file shows `added_by: injected_after:010.01`.
6. **Renumbering audit** — the copied renumbered target step file aligns with numbering shifts shown in status output after sibling injection.
7. **Dynamic audit** — the copied top-level dynamic step file shows `added_by: dynamic`.

## Verdict

- **PASS**: Tree display shows hierarchy with indicators and nested numbers, and the real assignment step files validate child, injected, renumbered, and dynamic mutations.
- **FAIL**: Hierarchy display is incorrect or the real step files do not match the claimed mutations.

Report: `PASS` or `FAIL` with evidence (status output excerpts, metadata citations).
