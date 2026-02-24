# Goal 1 — Injection and Renumbering Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Children created** — Child injection outputs show exit code 0. Phase files 010.01, 010.02, 010.03 created.
2. **Child metadata** — Phase files contain parent: "010" and added_by: child_of:010.
3. **Sibling injection** — `sibling-inject.stdout` shows new phase as 010.02 with "sibling after 010.01" relationship. Renumbering announced.
4. **Renumbering metadata** — Renumbered phase file contains renumbered_from and renumbered_at fields. Old file location no longer exists.
5. **Cascade renumbering** — Grandchild cascades when parent is renumbered (e.g., 010.03.01 -> 010.04.01). All shifted phases have renumbered_from metadata.

## Verdict

- **PASS**: Child injection, sibling injection with renumbering, and cascade renumbering all produce correct numbering and metadata.
- **FAIL**: Incorrect numbering, missing metadata, or cascade renumbering failure.

Report: `PASS` or `FAIL` with evidence (phase numbers, metadata citations).
