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
3. **Child completion commands succeeded**.
4. **Parent auto-completes after all children are done**.
5. **Queue advances to next top-level step**.

### Multi-Level
6. **Grandparent/parent/grandchild hierarchy exists**.
7. **Grandchild completion command succeeded**.
8. **Ancestor cascade auto-completion occurs**.
9. **Auto-completion report/state evidence exists for ancestors**.
10. **Queue advances to the next top-level step**.

## Verdict

- **PASS**: Single-level and multi-level auto-completion both produce expected completion cascades and queue advancement.
- **FAIL**: Cascade or advancement evidence is missing/contradictory.

Report: `PASS` or `FAIL` with evidence (status transitions and report artifacts).
