# Goal 4 — Error Handling

## Goal

Request a non-existent resource via `ace-nav` and verify the tool produces a graceful, informative error — not a stack trace or cryptic failure.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/missing-resource.stdout`, `.stderr`, `.exit` — resolving a resource that does not exist

## Constraints

- Use `ace-nav` with a clearly non-existent resource name (e.g., `guide://nonexistent-resource`).
- Using what you learned from Goal 1, invoke ace-nav appropriately. Do not assume syntax beyond what Goal 1 revealed.
- All artifacts must come from real tool execution, not fabricated.
