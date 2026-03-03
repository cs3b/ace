# Goal 3 — Move Idea

## Goal

Move the created idea to `_next/` with `ace-idea update {id} --move-to next`.
Then verify filesystem relocation by confirming the file now exists under
`.ace-ideas/_next/` and no longer in the root `.ace-ideas/` folder.
Also run `ace-idea list --in next` to confirm the moved idea appears in
the filtered listing.

## Workspace

Save artifacts to `results/tc/03/`.

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Do not write outside the sandbox.
