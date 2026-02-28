# Goal 1 — Create Idea Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `.ace-ideas/` directory exists in the sandbox root.
2. At least one `.md` file exists under `.ace-ideas/` with YAML frontmatter containing `id:`, `title:`, and `status:`.
3. Exit code is `0`.
4. `stdout` includes `Idea created:` with a B36TS ID and path line.

## Verdict

- **PASS**: Idea file exists on disk with valid frontmatter and creation output confirmed.
- **FAIL**: Missing file, invalid frontmatter, or non-zero exit code.
