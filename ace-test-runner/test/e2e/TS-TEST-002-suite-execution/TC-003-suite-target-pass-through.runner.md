# Goal 3 — Suite Target Pass-Through

## Goal

Run `ace-test-suite --config .ace/test/suite.yml --target fast`
and capture evidence that suite-target routing works through the public CLI.

## Workspace

Save artifacts to `results/tc/03/`.

Capture:
- `results/tc/03/command.txt` - exact command used
- `results/tc/03/stdout.txt` - command stdout
- `results/tc/03/stderr.txt` - command stderr (can be empty)
- `results/tc/03/command.exit` - numeric exit code from the command

Execution guidance:
1. Run one command from the sandbox root:
   - `ace-test-suite --config .ace/test/suite.yml --target fast`
2. Persist artifacts under `results/tc/03/` even when the command fails.

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Do not write outside the sandbox.
