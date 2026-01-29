# CLI Exit Codes

This document describes the exit codes returned by the `ace-coworker` CLI.

## Exit Code Reference

| Code | Meaning | Example Scenario |
|------|---------|------------------|
| 0 | Success | Command executed successfully |
| 1 | General error | Unhandled error, invalid step reference, report rejected on stalled queue |
| 2 | No active session | Running `status` or `report` when no session is active |
| 3 | File not found | Config file or report file does not exist |

## Exit Code Details

### Exit Code 0: Success
The command executed successfully. This includes:
- Creating a session (`create`)
- Adding a step (`add`)
- Retrying a step (`retry`)
- Marking a step as failed (`fail`)
- Displaying status (`status`)
- Submitting a report (`report`)

### Exit Code 1: General Error
An error occurred that doesn't fit into other categories:
- Invalid step reference (e.g., `report` with invalid step number)
- Report rejected when queue is stalled (no step currently in progress)
- Other unhandled errors

### Exit Code 2: No Active Session
No active session exists. Commands that require an active session return this code:
- `status` when no session has been created
- `report` when no session has been created

### Exit Code 3: File Not Found
A required file could not be found:
- Config file does not exist when running `create`
- Report file does not exist when running `report`

## See Also

- [CLI Reference](../README.md#cli-commands)
- [Error Handling](../README.md#error-handling)
