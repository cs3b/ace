# Goal 1 — Idea Capture Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Idea directory created** — `.ace-ideas/` exists in the sandbox.
2. **Idea file exists** — `results/tc/01/idea-path.txt` contains a path ending in `.idea.s.md`, and that file exists in the sandbox.
3. **Create succeeded** — `results/tc/01/create.exit` contains `0`.
4. **List works** — `results/tc/01/list.stdout` mentions the created idea (references "retry" or "webhook").
5. **Tree shows structure** — `results/tc/01/tree.stdout` shows the `.ace-ideas/` directory with at least one subdirectory containing a `.idea.s.md` file.

## Verdict

- **PASS**: Idea created successfully, file exists with `.idea.s.md` extension, list command shows it.
- **FAIL**: Create failed, file missing, or list doesn't show the idea.

Report: `PASS` or `FAIL` with evidence.
