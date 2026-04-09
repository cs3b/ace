# Goal 1 — Create Idea

## Goal

Create an idea with `ace-idea create` and capture command output, created idea
reference, and confirm the idea file was written to `.ace-ideas/`.

## Workspace

Save artifacts to `results/tc/01/`.

Capture:
- `results/tc/01/create.stdout`, `.stderr`, `.exit`
- `results/tc/01/idea-file.path` — path to the created idea file
- `results/tc/01/idea-file.md` — copied idea file content, including frontmatter

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
