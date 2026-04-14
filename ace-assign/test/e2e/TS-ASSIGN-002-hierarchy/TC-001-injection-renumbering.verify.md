# Goal 1 — Injection and Renumbering Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Use runner observations to locate the active assignment when needed.
3. Confirm command captures under `results/tc/01/`.
4. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Children created** — Child injection succeeds and assignment state shows `010.01`, `010.02`, and `010.03` under parent `010`.
2. **Sibling injection renumbered the branch** — later state shows the injected sibling at `010.02` and the original child shifted to `010.03`.
3. **Grandchild placement before second renumber** — `status_after_grandchild.*` or `add_grandchild_under_renumbered.*` shows `grandchild-01` at `010.03.01`.
4. **Cascade renumbering** — final assignment state shows `sibling-after-parent-renumber` at `010.03`, `child-02` at `010.04`, and the descendant as `010.04.01`, proving the grandchild shifted when the parent shifted.

## Verdict

- **PASS**: Child injection, sibling injection with renumbering, and cascade renumbering all produce the correct final assignment state.
- **FAIL**: Incorrect numbering, missing child/injection metadata, or cascade renumbering failure.

Report: `PASS` or `FAIL` with evidence (step numbers, metadata citations).
