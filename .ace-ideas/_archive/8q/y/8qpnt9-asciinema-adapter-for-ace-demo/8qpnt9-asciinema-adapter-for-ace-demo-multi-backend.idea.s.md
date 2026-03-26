---
id: 8qpnt9
status: done
title: asciinema adapter for ace-demo multi-backend recording
tags: [ace-demo, recording, asciinema, adapter, verification]
created_at: "2026-03-26 15:52:30"
---

# Add asciinema recording adapter to ace-demo

## What I Hope to Accomplish
Introduce a text-based recording format to `ace-demo` via `asciinema` to enable automated verification of terminal demos. By capturing sessions as `.cast` JSON files, we can programmatically confirm that commands ran correctly and produced the expected output, while also providing reviewers with searchable, lightweight demo artifacts that are more efficient than binary GIFs.

## What "Complete" Looks Like
An `asciinema` adapter is fully integrated into `ace-demo` alongside the existing `VHS` implementation, following the established `CommandBuilder`/`Executor` pattern. The system supports dual-output recording where `asciinema` provides the verifiable text source and `agg` (or `VHS`) provides the visual GIF, allowing the `record-demo` workflow to use text parsing for CI verification.

## Success Criteria
- `AsciinemaCommandBuilder` and `AsciinemaExecutor` implemented following the existing ATOM pattern.
- Successfully record terminal sessions to `.cast` JSON files.
- Verification logic can parse `.cast` files to validate command execution and output.
- `VHS` recording remains fully functional as a parallel recording option.
- `record-demo` assignment step updated to support `asciinema` for verification.
