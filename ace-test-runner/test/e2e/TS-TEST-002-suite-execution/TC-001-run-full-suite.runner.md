# Goal 1 — Run Full Suite

## Goal

Run `ace-test-suite --config .ace/test/suite.yml` from the sandbox root
and capture output showing
suite-level package aggregation behavior.

## Workspace

Save artifacts to `results/tc/01/`.

Capture:
- `results/tc/01/command.txt` - exact command used
- `results/tc/01/stdout.txt` - command stdout
- `results/tc/01/stderr.txt` - command stderr (can be empty)
- `results/tc/01/.exit` - numeric exit code from the command

Execution guidance:
1. Run exactly one suite command from the sandbox root:
   - `ace-test-suite --config .ace/test/suite.yml`
2. Persist artifacts under `results/tc/01/` even when the command fails.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
