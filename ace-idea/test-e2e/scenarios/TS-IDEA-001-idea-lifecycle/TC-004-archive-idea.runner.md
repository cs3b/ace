# Goal 4 — Archive Idea

## Goal

Move the idea to archive scope with `ace-idea update {id} --move-to archive`.
Then run `ace-idea list --in archive` to confirm archived ideas are visible
through folder filtering.

## Workspace

Save artifacts to `results/tc/04/`.

Capture:
- `results/tc/04/idea-id.txt` — exact idea ID reused from TC-001
- `results/tc/04/update-archive.stdout`, `.stderr`, `.exit`
- `results/tc/04/list-archive.stdout`, `.stderr`, `.exit`
- `results/tc/04/archive-files.txt` — filesystem proof of archived `.idea.s.md` files under `.ace-ideas/_archive`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/04/`.
- Do not write outside the sandbox.
- Reuse the exact idea ID from `results/tc/01/idea-file.md` frontmatter (`id:`). Do not pass filename or path to `ace-idea update`.
- Save the extracted ID to `results/tc/04/idea-id.txt` before running the archive update command.
- After the archive move, capture a filesystem listing under `.ace-ideas/_archive` that shows the moved `.idea.s.md` file.
