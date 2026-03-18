# Goal 2 — Verify Failure Propagation

## Goal

Create a minimal failing test file in a temporary package fixture, invoke the
suite (or focused package run), and capture non-zero exit propagation.

## Workspace

Save artifacts to `results/tc/02/`.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
- Do not write outside the sandbox.
- If this goal creates `ace-test-runner/test/atoms/intentional_failure_test.rb`, remove it before finishing by running `rm -f ace-test-runner/test/atoms/intentional_failure_test.rb`.
