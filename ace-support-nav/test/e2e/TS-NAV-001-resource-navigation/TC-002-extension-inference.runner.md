# Goal 2 — Public Resolve Journey (Guide + Workflow)

## Goal

Execute one realistic user job: resolve a guide and a workflow through public CLI usage, then capture outputs proving both targets are usable resolved paths.

## Workspace

Save all output to `results/tc/02/`.

Capture artifacts:
- `results/tc/02/guide-resolve.stdout`, `.stderr`, `.exit` — resolve a guide URI
- `results/tc/02/workflow-resolve.stdout`, `.stderr`, `.exit` — resolve a workflow URI

## Constraints

- Use `ace-nav resolve` with protocol URIs discovered from Goal 1.
- Prefer representative public resources from fixtures (guide + workflow) without testing fallback-priority internals.
- Focus on user-visible success: successful resolution and usable output paths.
- All artifacts must come from real command execution.
