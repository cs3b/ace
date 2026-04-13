# Goal 1 — Process and Archive

## Goal

Place a sample prompt file into the workspace created by scenario setup, then process it using `ace-prompt-prep`. Verify that processing archives the prompt with a Base36 timestamp ID and that a `_previous.md` symlink points to the archived file.

## Workspace

Save all output to `results/tc/01/`. Capture:
- `process.stdout`, `process.stderr`, `process.exit` from process invocation
- `archive-list.txt` listing archived file(s)
- `previous-link.txt` showing `_previous.md` symlink target
- `content-diff.txt` or equivalent content comparison output

## Constraints

- Copy `sample-prompt.md` from the fixtures directory into the prompt workspace before processing.
- Use only `ace-prompt-prep` to process the prompt. Do not manually create archive files.
- The archive filename should contain a Base36 ID (lowercase alphanumeric characters) — verify this from the actual directory listing.
- All artifacts must come from real tool execution, not fabricated.
