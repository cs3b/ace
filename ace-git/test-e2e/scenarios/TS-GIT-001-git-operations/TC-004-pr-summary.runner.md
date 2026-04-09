# Goal 4 — PR Summary

## Goal

Run `ace-git pr` first. If PR context is unavailable in this sandbox, run
`ace-git status --no-pr` as an explicit fallback and capture both attempts.

## Workspace

Save artifacts to `results/tc/04/`.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/04/`.
- Do not write outside the sandbox.
- First attempt must capture `ace-git pr` as `pr.stdout|stderr|exit`.
- If `ace-git pr` exits non-zero due to missing PR context, capture one fallback
  command `ace-git status --no-pr` as `status-no-pr.stdout|stderr|exit`.
- Do not retry more than once for either command.
