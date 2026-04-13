# Goal 1 — Run Full Suite

## Goal

Read `.monorepo-root` to get the actual monorepo path, cd to that directory,
then run `ace-test-suite` with explicit suite config and capture output showing
suite-level package aggregation behavior.

## Workspace

Save artifacts to `results/tc/01/`.

Capture:
- `results/tc/01/command.txt` - exact command used
- `results/tc/01/stdout.txt` - command stdout
- `results/tc/01/stderr.txt` - command stderr (can be empty)
- `results/tc/01/.exit` - numeric exit code from the command

Execution guidance:
1. Resolve monorepo root from `.monorepo-root` (fallback to current directory if missing).
2. If an `ace-test-runner/` directory exists in that root, run from `ace-test-runner/`; otherwise run from the resolved root.
3. Run one suite command:
   - preferred: `./exe/ace-test-suite --config .ace/test/suite.yml`
   - fallback if config path fails: `./exe/ace-test-suite`
4. Persist artifacts under `results/tc/01/` even when the command fails.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
