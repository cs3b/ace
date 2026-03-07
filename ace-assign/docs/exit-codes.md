# CLI Exit Codes

This document describes the exit codes returned by the `ace-assign` CLI.

## Exit Code Reference

| Code | Meaning | Example Scenario |
|------|---------|------------------|
| 0 | Success | Command executed successfully |
| 1 | General error | Unhandled error, invalid phase reference, finish rejected on stalled queue |
| 2 | No active assignment | Running `status` or `finish` when no assignment is active |
| 3 | File not found | Config file does not exist |

## Exit Code Details

### Exit Code 0: Success
The command executed successfully. This includes:
- Creating an assignment (`create`)
- Adding a phase (`add`)
- Retrying a phase (`retry`)
- Marking a phase as failed (`fail`)
- Displaying status (`status`)
- Finishing a phase (`finish`)

### Exit Code 1: General Error
An error occurred that doesn't fit into other categories:
- Invalid phase reference (e.g., `finish` with invalid phase number)
- Report rejected when queue is stalled (no phase currently in progress)
- Missing report input for `finish` (`--message` absent/blank and no piped stdin)
- Other unhandled errors

### Exit Code 2: No Active Assignment
No active assignment exists. Commands that require an active assignment return this code:
- `status` when no assignment has been created
- `finish` when no assignment has been created

### Exit Code 3: File Not Found
A required file could not be found:
- Config file does not exist when running `create`

## See Also

- [CLI Reference](../README.md#cli-commands)
- [Error Handling](../README.md#error-handling)
