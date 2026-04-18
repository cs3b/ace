# Goal 2 — Verify Failure Propagation

## Goal

Create a minimal failing fast test inside the sandboxed `ace-test-runner`
package, invoke the suite against the scenario-local suite config, and capture
non-zero exit propagation.

## Workspace

Save artifacts to `results/tc/02/`.

Capture:
- `results/tc/02/command.txt` - exact command used
- `results/tc/02/stdout.txt` - command stdout
- `results/tc/02/stderr.txt` - command stderr (can be empty)
- `results/tc/02/.exit` - numeric exit code from the command (must be non-zero)
- `results/tc/02/injected-test.path` - path to the temporary failing test file
- `results/tc/02/precheck.command.txt` - exact `ace-test` command used for the injected file
- `results/tc/02/precheck.stdout` - direct failing-test stdout
- `results/tc/02/precheck.stderr` - direct failing-test stderr
- `results/tc/02/precheck.exit` - numeric exit code from the direct failing-test run

Execution guidance:
1. Create `ace-test-runner/test/fast/atoms/intentional_failure_test.rb` inside the sandbox with one deterministic failing test whose class name or failure message is uniquely identifiable (for example `IntentionalFailureTest` and `INTENTIONAL_E2E_FAILURE_SENTINEL`).
2. Save that file path to `results/tc/02/injected-test.path`.
3. Run `ace-test <path-from-injected-test.path>` first and persist `precheck.command.txt`, `precheck.stdout`, `precheck.stderr`, and `precheck.exit`. The precheck must fail non-zero and its output must visibly reference the injected file, test class, or sentinel message.
4. Run `ace-test-suite --config .ace/test/suite.yml --target fast`.
5. Persist `command.txt`, `stdout.txt`, `stderr.txt`, and `.exit` even when the suite command fails.
6. Remove `ace-test-runner/test/fast/atoms/intentional_failure_test.rb` before finishing the goal.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
- Do not write outside the sandbox.
