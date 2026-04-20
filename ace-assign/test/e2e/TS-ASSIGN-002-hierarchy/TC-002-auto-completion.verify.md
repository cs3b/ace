# Goal 2 — Auto-Completion Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/02/`.
3. Use report/status evidence as primary oracle.
4. Use debug evidence only as fallback.

### Single-Level
1. **Children exist under parent**.
2. **Parent cannot finish early while children remain incomplete**.
3. **Targeting is valid** — `select-single.exit`, `finish-single-1.exit`, and
   `finish-single-2.exit` are `0`; stderr must not contain the positional
   `STEP` plus `--assignment` error.
4. **Child completion commands succeeded**.
5. **Parent auto-completes after all children are done**.
6. **Queue advances to next top-level step**.

### Multi-Level
7. **Grandparent/parent/grandchild hierarchy exists**.
8. **Targeting is valid** — `select-multi.exit` and `finish-multi-1.exit` are
   `0`; stderr must not contain the positional `STEP` plus `--assignment`
   error.
9. **Grandchild completion command succeeded**.
10. **Ancestor cascade auto-completion occurs**.
11. **Auto-completion report/state evidence exists for ancestors**.
12. **Queue advances to the next top-level step**.

## Verdict

- **PASS**: Single-level and multi-level auto-completion both produce expected completion cascades and queue advancement.
- **FAIL**: Cascade or advancement evidence is missing/contradictory.

Report: `PASS` or `FAIL` with evidence (status transitions and report artifacts).
