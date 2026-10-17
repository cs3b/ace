---
doc-type: user
title: CLI Exit Codes
purpose: Exit codes for the local ace-assign lifecycle commands.
ace-docs:
  last-updated: 2026-10-17
  last-checked: 2026-10-17
---

# CLI Exit Codes

Exit codes returned by the local `ace-assign` lifecycle commands.

## Exit Code Reference

| Code | Meaning | Example Scenario |
|------|---------|------------------|
| 0 | Success | `create`, `add`, `retry`, `fail`, `status`, `step`, `start`, `finish` completed |
| 1 | General error | Invalid step reference, report rejected when no step is in progress, missing report input, unhandled error |
| 2 | Assignment error | No active assignment or unknown assignment ID |
| 3 | Configuration not found | Required config file is missing during `create` |
| 4 | Step not found | `retry` or another command references a step that does not exist |
| 130 | Interrupted | SIGINT during a command |

## Exit Code Details

### Exit Code 1: General Error

- `finish` with an invalid step number
- `finish` when no step is in progress
- `finish` with no report content (`--message` absent/blank and no piped stdin)
- Other unhandled errors

### Exit Code 2: Assignment Error

- No active assignment for a command that needs one (`status`, `finish`)
- `--assignment` names an assignment that does not exist

### Exit Code 3: Configuration Not Found

`create` cannot read the required configuration or YAML input.

### Exit Code 4: Step Not Found

The requested step reference does not exist in the target assignment.

## See Also

- [Usage Guide](usage.md) for the full command reference
- [Getting Started](getting-started.md) for a tutorial
