# Goal 1 — Injection and Renumbering Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Children created** — Child injection outputs show exit code 0. Step files 010.01, 010.02, 010.03 created.
2. **Child metadata** — Prefer step-file metadata (`parent: "010"`, `added_by: child_of:010`). If metadata files are missing, accept status/output evidence that children were added under 010.
3. **Sibling injection** — Sibling-injection output shows new step as 010.02 with "after 010.01" relationship, or equivalent status snapshots showing the same renumbering effect.
4. **Renumbering evidence** — Status snapshots before/after sibling injection show numbering shifts consistent with renumbering.
5. **Cascade renumbering** — Grandchild numbering shifts when parent numbering shifts (status evidence is sufficient; explicit `renumbered_from` metadata is optional).

## Verdict

- **PASS**: Child injection, sibling injection with renumbering, and cascade renumbering all produce correct numbering/state evidence.
- **FAIL**: Incorrect numbering, missing child/injection metadata, or cascade renumbering failure.

Report: `PASS` or `FAIL` with evidence (step numbers, metadata citations).
