# Goal 1 — Basic Query

## Goal

Run `ace-llm gflash --prompt "Summarize this sentence in one short sentence: ACE E2E coverage is improving."`
and capture the response output and exit code.

## Workspace

Save artifacts to `results/tc/01/`.

## Constraints

- Use real provider invocation; do not mock responses.
- If credentials are missing, capture the explicit error output.
- Do not write helper prompt-tracking files under `results/`.
- Mention the exact command and prompt you used in final runner observations.
- If stdout asks for missing input instead of answering the prompt, that is failure evidence for this goal.
