# Goal 2 — Git Diff

## Goal

Create a known file change, run `ace-git diff`, and capture output showing the
change appears in diff formatting.

## Workspace

Save artifacts to `results/tc/02/`.
## Setup Sequence (mandatory)

1. Create a tracked file and commit it: `echo "initial content" > tracked.txt && git add tracked.txt && git commit -m "add tracked file"`.
2. Append a new line without committing: `echo "added line" >> tracked.txt`.
3. Capture the mutation evidence: save the output of `cat tracked.txt` to `results/tc/02/setup.stdout`.
4. Now run `ace-git diff` and capture stdout/stderr/exit to `results/tc/02/diff.*`.

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
- Do not write outside the sandbox.
- The file MUST be tracked (committed at least once) before modification, otherwise `ace-git diff` will not detect the change.
- Capture setup evidence before collecting `ace-git diff` captures.
