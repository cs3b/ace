# Goal 2 — Auto-Completion Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
### Single-Level
1. **Children created** — Two children (010.01, 010.02) exist under parent 010.
2. **Parent protection** — Parent completion blocked while children incomplete.
3. **Completion commands succeeded** — `finish_child1.exit` and `finish_child2.exit` are `0`.
4. **Sequential child completion** — After completing child one, child two becomes current; parent remains pending.
5. **Parent auto-completes** — After completing all children, parent 010 auto-completes. Prefer copied report evidence in `results/tc/02/`; if unavailable, accept direct status/output evidence that parent transitioned automatically.
6. **Advancement** — Workflow advances to 020-final-step.

### Multi-Level
7. **Hierarchy built** — 010 (grandparent), 010.01 (parent), 010.01.01 (grandchild) hierarchy established.
8. **Grandchild completion command succeeded** — `finish_grandchild.exit` is `0`.
9. **Cascade auto-completion** — After finishing 010.01.01, both 010.01 and 010 must be done in `status_multi_after.*` or equivalent status evidence. Pending ancestors are a failure.
10. **Reports generated** — Report evidence must show auto-completion artifacts for both ancestors. Accept copied report artifacts in `results/tc/02/` or equivalent report listings (`list_reports_multi.*`) that clearly show both ancestor reports were generated.
11. **Next step current** — 020-next-task becomes in_progress after cascade.

## Verdict

- **PASS**: Single-level auto-completion works and multi-level completion finishes the grandchild, auto-completes both ancestors, generates ancestor report evidence, and advances to the next top-level step.
- **FAIL**: Single-level flow is broken, completion commands fail broadly, or workflow becomes invalid/stuck.

Report: `PASS` or `FAIL` with evidence (step states, report content, status output).
