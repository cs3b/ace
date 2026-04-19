# Goal 2 — Bundle Context Processing

## Goal

Create a prompt containing a `context` block and process it with `ace-prompt-prep --bundle`.
Verify that command execution succeeds, context-expanded output is captured, and archive lifecycle
behavior still works with context mode enabled.

## Workspace

Save all output to `results/tc/02/`. Capture:
- `bundle.stdout`, `bundle.stderr`, `bundle.exit` from process invocation with `--bundle`
- `bundle-output.md` containing processed output for evidence review
- `bundle-prompt-source.md` containing the exact prompt content used for this goal
- `bundle-archive-list.txt` listing archive directory files after the run
- `bundle-previous-link.txt` showing `_previous.md` symlink target

## Constraints

- Use only `ace-prompt-prep` for processing; do not fabricate archive artifacts.
- Prepare the prompt content before invocation so it includes:
  - a unique marker token in the body: `BUNDLE_CONTEXT_CHECKPOINT`
  - a `bundle.sources` block with at least one resolvable source (prefer `ace-prompt-prep/docs/usage.md`)
- After saving `bundle.stdout`, immediately copy the same processed stdout content to `results/tc/02/bundle-output.md`.
- If stdout is empty, still create `bundle-output.md` as an empty file so missing-output and empty-output failures are distinguishable.
- Validate from captured artifacts, not assumptions, that context mode did not break archive behavior.
