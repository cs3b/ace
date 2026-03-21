---
doc-type: user
title: CLI Exit Codes
purpose: Documentation for ace-assign/docs/exit-codes.md
ace-docs:
  last-updated: 2026-03-18
  last-checked: 2026-03-21
---

# CLI Exit Codes

This document describes the exit codes returned by the `ace-assign` CLI.

## Exit Code Reference

| Code | Meaning | Example Scenario |
|------|---------|------------------|
| 0 | Success | Command executed successfully |
| 1 | General error | Unhandled error, invalid step reference, finish rejected on stalled queue |
| 2 | Assignment error | No active assignment or assignment not found |
| 3 | Configuration not found | Config file does not exist |
| 4 | Step not found | Referencing a step that does not exist |

## Exit Code Details

### Exit Code 0: Success
The command executed successfully. This includes:
- Creating an assignment (`create`)
- Adding a step (`add`)
- Retrying a step (`retry`)
- Marking a step as failed (`fail`)
- Displaying status (`status`)
- Finishing a step (`finish`)

### Exit Code 1: General Error
An error occurred that doesn't fit into other categories:
- Invalid step reference (e.g., `finish` with invalid step number)
- Report rejected when queue is stalled (no step currently in progress)
- Missing report input for `finish` (`--message` absent/blank and no piped stdin)
- Other unhandled errors

### Exit Code 2: Assignment Error
Assignment state is invalid for the requested command:
- No active assignment exists. Commands that require an active assignment return this code:
- `status` when no assignment has been created
- `finish` when no assignment has been created
- Assignment ID does not exist (for commands targeting a specific assignment)

### Exit Code 3: Configuration Not Found
A required configuration file could not be found:
- Config file does not exist when running `create`

### Exit Code 4: Step Not Found
The requested step reference does not exist in the target assignment:
- `retry` with unknown step number
- Commands that target a specific missing step

## See Also

- [CLI Reference](../README.md#cli-commands)
- [Error Handling](../README.md#error-handling)
