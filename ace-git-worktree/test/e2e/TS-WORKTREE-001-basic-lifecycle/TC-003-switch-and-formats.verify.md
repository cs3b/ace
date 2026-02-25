# Goal 3 — Switch and Output Formats Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **All capture sets exist** — results/tc/03/ contains stdout/exit for switch, list-table, list-json, and list-simple.
2. **Switch returns valid path** — switch.stdout contains a filesystem path and switch.exit is 0.
3. **JSON is parseable** — list-json.stdout contains valid JSON (array or object with worktree entries).
4. **Table has headers** — list-table.stdout includes header-like text (column names or separator lines).
5. **Simple is compact** — list-simple.stdout is shorter or less decorated than the table output.

## Verdict

- **PASS**: Switch returns a path, all three formats produce distinct well-formed output.
- **FAIL**: Switch fails, JSON is unparseable, or format outputs are missing or identical.

Report: `PASS` or `FAIL` with evidence (path from switch, format output snippets).
