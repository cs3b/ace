# Goal 6 — Create From Public Path

## Goal

Run a real create journey from public CLI usage: choose a template-style URI from prior discovery and create an output file, proving end-to-end user-visible creation behavior.

## Workspace

Save all output to `results/tc/06/`.

Capture artifacts:
- `results/tc/06/create.stdout`, `.stderr`, `.exit` — create command output
- `results/tc/06/created.path` — newline-terminated path to the created file for verifier lookup

## Constraints

- Use `ace-nav create URI TARGET` with URI syntax learned from help/discovery goals.
- The created file must be under `results/tc/06/`.
- Do not fabricate file content; output must be produced by real command execution.
- If create fails, still persist stdout/stderr/exit for verification.
