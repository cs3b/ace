# Goal 1 — Idea Capture Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) as fallback.

1. **Create command executed successfully** — `results/tc/01/create.exit` is numeric and `0`.
2. **Idea path is captured** — `results/tc/01/idea-path.txt` exists and contains an existing `.idea.s.md` path.
3. **List output includes the created idea title** — `results/tc/01/list.stdout` exists and references "webhook" while the ID in `results/tc/01/idea-id.txt` is non-empty.
4. **Show output is captured and resolves the same ID** — `results/tc/01/show.exit` is `0`, and `results/tc/01/show.stdout` includes the extracted idea ID and "Add retry logic to webhook delivery".
5. **Tree evidence is concrete** — `results/tc/01/tree.stdout` lists at least one `.ace-ideas` `.idea.s.md` file.

## Verdict

- **PASS**: Create/list/show complete the documented flow and references are consistent:
  - `create.exit` is `0`
  - idea path and idea-id artifacts exist
  - list and show outputs reference the same item
  - show output includes the idea title
- **FAIL**: Any missing artifact, non-zero command exit for create/show, or inconsistent IDs.

Report: `PASS` or `FAIL` with evidence (artifact file names and key snippets).
