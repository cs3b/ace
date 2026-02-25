# Goal 1 — Basic Query

## Goal

Run `ace-llm gflash "Summarize this test in one sentence."` and capture the
response output and exit code.

## Workspace

Save artifacts to `results/tc/01/`.

## Constraints

- Use real provider invocation; do not mock responses.
- If credentials are missing, capture the explicit error output.
