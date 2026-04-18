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
4. **Table output is usable** — list-table.exit is 0 and list-table.stdout contains non-empty entry content.
5. **Simple output is usable** — list-simple.exit is 0 and list-simple.stdout contains non-empty entry content.

## Verdict

- **PASS**: Switch path resolves, JSON parses, and all three format commands produce usable output.
- **FAIL**: Switch fails, JSON is unparseable, or required artifacts are missing/empty.

Report: `PASS` or `FAIL` with evidence (path from switch, format output snippets).
