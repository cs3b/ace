# Goal 3 — Display and Audit Trail Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
### Tree Display
1. **All steps shown** — `status-tree.stdout` should show the hierarchy for both parents with nested children. Missing one optional child label is not an automatic failure if numbering/tree structure and other hierarchy entries are present.
2. **Hierarchy indicators** — Status uses tree characters (pipe |, tee, elbow, or similar hierarchy markers).
3. **Nested numbers** — Status shows nested step numbers 010.01, 010.02, 020.01.

### Audit Trail
4. **Child audit** — `child-of-metadata.stdout` must exist and show `added_by: child_of:010` and `parent: "010"`.
5. **Injection audit** — `injected-after-metadata.stdout` must exist and show `added_by: injected_after:010.01`.
6. **Renumbering audit** — `renumbered-metadata.stdout` must exist and align with numbering shifts shown in status snapshots after sibling injection.
7. **Dynamic audit** — `dynamic-metadata.stdout` must exist and show `added_by: dynamic`.
8. **Artifact integrity** — `renumbered-metadata.stdout` and `dynamic-metadata.stdout` represent different steps (renumbered vs dynamic) and are not swapped.

Path discipline for verdict:
- Missing `.yaml` files is not failure evidence by itself; step artifacts are `.st.md`.
- Missing or swapped metadata artifacts are a FAIL for this goal because the audit contract requires explicit artifact capture.

## Verdict

- **PASS**: Tree display shows hierarchy with indicators and nested numbers, and all four explicit audit metadata artifacts validate child, injected, renumbered, and dynamic mutations.
- **FAIL**: Hierarchy display is incorrect, any required metadata artifact is missing, or the audit artifacts do not match the claimed mutations.

Report: `PASS` or `FAIL` with evidence (status output excerpts, metadata citations).
