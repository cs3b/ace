# Goal 4 — Display and Audit Trail Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
### Tree Display
1. **All steps shown** — `status-tree.stdout` contains feature-a, a-subtask-1, a-subtask-2, feature-b, b-subtask-1.
2. **Hierarchy indicators** — Status uses tree characters (pipe |, tee, elbow, or similar hierarchy markers).
3. **Nested numbers** — Status shows nested step numbers 010.01, 010.02, 020.01.

### Audit Trail
4. **Child audit** — `child-of-metadata.stdout` shows `added_by: child_of:010` and `parent: "010"` from real step `.st.md` content.
5. **Injection audit** — `injected-after-metadata.stdout` shows `added_by: injected_after:010.01` from injected step `.st.md`.
6. **Renumbering audit** — `renumbered-metadata.stdout` is non-empty and shows `renumbered_from` with old number and `renumbered_at` with ISO8601 timestamp from the real renumbered step `.st.md`.
7. **Dynamic audit** — `dynamic-metadata.stdout` is non-empty and shows `added_by: dynamic` (not `injected_after:*`).
8. **Artifact integrity** — `renumbered-metadata.stdout` and `dynamic-metadata.stdout` represent different steps (renumbered vs dynamic) and are not swapped.

Path discipline for verdict:
- Missing `.yaml` files is not failure evidence by itself; step artifacts are `.st.md`.
- If metadata check fails, treat wrong assignment-id/path/extension lookup as runner artifact error, not tool behavior regression.

## Verdict

- **PASS**: Tree display shows hierarchy with indicators and nested numbers. All four audit trail types (child, injected, renumbered, dynamic) correctly populated.
- **FAIL**: Missing hierarchy display, incorrect audit metadata, or missing audit trail types.

Report: `PASS` or `FAIL` with evidence (status output excerpts, metadata citations).
