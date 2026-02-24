# Goal 3 — Process and Archive

## Goal

Place a sample prompt file into the workspace created in Goal 2, then process it using `ace-prompt-prep`. Verify that processing archives the prompt with a Base36 timestamp ID and that a `_previous.md` symlink points to the archived file.

## Workspace

Save all output to `results/tc/03/`. Capture:
- The command's stdout, stderr, and exit code
- A listing of the archive directory showing the archived file(s)
- The symlink target of `_previous.md`
- A diff or comparison showing the archived content matches the original

## Constraints

- Copy `sample-prompt.md` from the fixtures directory into the prompt workspace before processing.
- Use only `ace-prompt-prep` to process the prompt. Do not manually create archive files.
- The archive filename should contain a Base36 ID (lowercase alphanumeric characters) — verify this from the actual directory listing.
- All artifacts must come from real tool execution, not fabricated.
