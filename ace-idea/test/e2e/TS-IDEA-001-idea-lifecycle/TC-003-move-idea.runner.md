# Goal 3 — Move Idea

## Goal

Move the created idea to root scope with `ace-idea update {id} --move-to next`.
Derive `{id}` from the visible `Idea created: <id> ...` line in
`results/tc/01/create.stdout`, save it to `results/tc/03/idea-id.txt`, then use that
ID for the update command.
After the update, verify filesystem state by confirming the idea remains under
`.ace-ideas/` (root scope), does not create a dedicated `_next/` directory, and is
visible in the `--in next` listing.

## Workspace

Save artifacts to `results/tc/03/`.

Capture:
- `results/tc/03/idea-id.txt` — exact idea ID reused from TC-001
- `results/tc/03/update.stdout`, `.stderr`, `.exit`
- `results/tc/03/list-next.stdout`, `.stderr`, `.exit`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Do not write outside the sandbox.
- Reuse the exact idea ID from the `Idea created:` line in `results/tc/01/create.stdout`.
- Do not pass the idea filename, basename, or path to `ace-idea update`.
- Save the extracted ID to `results/tc/03/idea-id.txt` before running the update command.
