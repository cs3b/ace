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
3. **Completion commands succeeded** — `complete-child1.exit` and `complete-child2.exit` are `0`.
4. **Sequential child completion** — After completing child one, child two becomes current; parent remains pending.
5. **Parent auto-completes** — After completing all children, parent 010 auto-completes. `parent-auto-complete.stdout` is the primary oracle; copied report artifacts are support evidence only when present.
6. **Advancement** — Workflow advances to 020-final-step.

### Multi-Level
7. **Hierarchy built** — 010 (grandparent), 010.01 (parent), 010.01.01 (grandchild) hierarchy established.
8. **Grandchild completion command succeeded** — `complete-grandchild.exit` is `0`.
9. **Cascade auto-completion** — Completing grandchild triggers parent auto-completion, which triggers grandparent auto-completion.
10. **Cascade evidence captured** — `cascade-auto-complete.stdout` is the primary oracle and shows that both ancestors auto-completed; copied report artifacts are support evidence only when present.
11. **Next step current** — 020-next-task becomes in_progress after cascade.

## Verdict

- **PASS**: Both single-level and multi-level auto-completion work with correct cascade behavior.
- **FAIL**: Auto-completion missing, cascade incomplete, or workflow stuck.

Report: `PASS` or `FAIL` with evidence (step states, report content, status output).
