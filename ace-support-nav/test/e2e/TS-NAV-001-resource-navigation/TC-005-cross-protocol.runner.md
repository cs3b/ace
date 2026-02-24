# Goal 5 — Cross-Protocol Inference

## Goal

Verify that extension inference works consistently across different protocols. Resolve a resource using the `wfi://` protocol and confirm the tool finds the shorthand `.wf.md` extension, just as `guide://` finds `.g.md`.

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/wfi-resolve.stdout`, `.stderr`, `.exit` — resolving a resource via `wfi://` protocol

## Constraints

- The sandbox fixtures include `setup.wf.md` for the wfi:// protocol.
- Use `ace-nav` with the `wfi://` protocol to resolve the resource without explicit extension.
- Using what you learned from Goal 1, invoke ace-nav appropriately. Do not assume syntax beyond what Goal 1 revealed.
- All artifacts must come from real tool execution, not fabricated.
