# Goal 4 — Display and Audit Trail Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Tree Display
1. **All phases shown** — `status-tree.stdout` contains feature-a, a-subtask-1, a-subtask-2, feature-b, b-subtask-1.
2. **Hierarchy indicators** — Status uses tree characters (pipe |, tee, elbow, or similar hierarchy markers).
3. **Nested numbers** — Status shows nested phase numbers 010.01, 010.02, 020.01.

### Audit Trail
4. **Child audit** — `child-of-metadata.stdout` shows `added_by: child_of:010` and `parent: "010"`.
5. **Injection audit** — `injected-after-metadata.stdout` shows `added_by: injected_after:010.01`.
6. **Renumbering audit** — `renumbered-metadata.stdout` shows `renumbered_from` with old number and `renumbered_at` with ISO8601 timestamp.
7. **Dynamic audit** — `dynamic-metadata.stdout` shows `added_by: dynamic`.

## Verdict

- **PASS**: Tree display shows hierarchy with indicators and nested numbers. All four audit trail types (child, injected, renumbered, dynamic) correctly populated.
- **FAIL**: Missing hierarchy display, incorrect audit metadata, or missing audit trail types.

Report: `PASS` or `FAIL` with evidence (status output excerpts, metadata citations).
