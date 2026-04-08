# Goal 1 — Injection and Renumbering Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Children created** — Child injection outputs show exit code 0. Step files 010.01, 010.02, 010.03 created.
2. **Direct renumbering captured** — `first-sibling-inject.stdout` shows the inserted sibling under 010 and `step-listing-after-first-renumber.stdout` shows the shifted child `child-b` at `010.03`.
3. **Parent renumber metadata** — `renumbered-parent.stdout` is the shifted `child-b` step and contains `added_by: child_of:010`, `parent: "010"`, `renumbered_from: 010.02`, and `renumbered_at`.
4. **Cascade pre-state captured** — `step-listing-before-cascade.stdout` contains the descendant path `010.03.01`.
5. **Cascade renumbering captured** — `second-sibling-inject.stdout` exits 0 and `step-listing-after-cascade.stdout` contains `010.04.01` while the old descendant path `010.03.01` is absent.
6. **Grandchild renumber metadata** — `renumbered-grandchild.stdout` contains `renumbered_from: 010.03.01`, `parent: "010.04"`, and `renumbered_at`.

## Verdict

- **PASS**: Child injection, direct renumbering, and descendant cascade renumbering all produce the expected before/after numbering and metadata.
- **FAIL**: Incorrect numbering, missing metadata, or missing explicit cascade evidence.

Report: `PASS` or `FAIL` with evidence (step numbers, metadata citations).
