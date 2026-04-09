# Goal 4 — Subject Processing

## Goal

Test subject processing with different subject types: (1) single diff:HEAD~1 subject, (2) single files:*.md subject, (3) multiple mixed subjects in one invocation. All via --dry-run to verify processing without API calls.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/diff-subject.stdout`, `.stderr`, `.exit` — diff subject
- `results/tc/04/files-subject.stdout`, `.stderr`, `.exit` — files subject
- `results/tc/04/mixed-subjects.stdout`, `.stderr`, `.exit` — multiple mixed subjects

## Constraints

- Use --dry-run with a valid preset (e.g., test or code).
- The sandbox has git history with a recent commit to README.md for diff subjects.
- Using what you learned from Goal 1, invoke with appropriate subject syntax.
- All artifacts must come from real tool execution, not fabricated.
