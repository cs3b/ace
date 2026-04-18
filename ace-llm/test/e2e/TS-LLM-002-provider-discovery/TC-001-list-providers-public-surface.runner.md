# Goal 1 — List Providers Public Surface

## Goal

Run `ace-llm --list-providers` and capture user-visible provider discovery output.

## Workspace

Save artifacts to `results/tc/01/`.

## Constraints

- Preserve raw output exactly.
- Do not infer provider availability from environment variables; use command output only.
- Capture stderr even when the command succeeds.
