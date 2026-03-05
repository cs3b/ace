# Goal 6 — JSON Output with Task Metadata Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **JSON artifacts exist** — results/tc/06/ contains list-json.stdout and list-json.exit.
2. **Valid JSON** — list-json.stdout contains well-formed JSON (parseable array or object).
3. **Task entries have metadata** — Task-associated entries contain task_id fields with values "8pp.t.q7w" and "8pp.t.r8x" (or equivalent identifiers) and branch fields.
4. **Non-task entries differ** — The main worktree entry has null, missing, or empty task_id field.

## Verdict

- **PASS**: JSON is valid, task worktrees have task_id and branch metadata, main worktree lacks task metadata.
- **FAIL**: JSON malformed, task metadata missing from task entries, or non-task entry incorrectly has task_id.

Report: `PASS` or `FAIL` with evidence (JSON snippets showing task_id fields).
