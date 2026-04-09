# Goal 4 — Bundle Context Processing

## Goal

Create a prompt containing a `context` block and process it with `ace-prompt-prep --bundle`.
Verify that command execution succeeds, context-expanded output is captured, and archive lifecycle
behavior still works with context mode enabled.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `bundle.stdout`, `bundle.stderr`, `bundle.exit` from process invocation with `--bundle`
- `bundle-output.md` containing processed output for evidence review
- `bundle-archive-list.txt` listing archive directory files after the run
- `bundle-previous-link.txt` showing `_previous.md` symlink target

## Constraints

- Use only `ace-prompt-prep` for processing; do not fabricate archive artifacts.
- Prepare the prompt content before invocation so it includes a `context` block with at least one
  resolvable source.
- Validate from captured artifacts, not assumptions, that context mode did not break archive behavior.
