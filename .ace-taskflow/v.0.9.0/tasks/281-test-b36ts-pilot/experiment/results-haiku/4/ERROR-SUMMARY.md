# Goal 4: Error Behavior — Summary

## Error Cases Tested

### Case 1: Invalid Subcommand
**Command**: `ace-b36ts foobar`

- **Exit Code**: 1
- **Stdout**: (empty)
- **Stderr**: Command help listing valid commands
- **Behavior**: Returns error code 1, outputs available commands to stderr (helpful)

### Case 2: Missing Required Argument
**Command**: `ace-b36ts decode` (no COMPACT_ID argument)

- **Exit Code**: 1
- **Stdout**: (empty)
- **Stderr**: Error message with usage hint
- **Behavior**: Returns error code 1, shows usage information to stderr

### Case 3: Invalid Token Format
**Command**: `ace-b36ts decode "xyz!!!"`

- **Exit Code**: 1
- **Stdout**: (empty)
- **Stderr**: Full error trace with Ruby stack
- **Behavior**: Returns error code 1, outputs error message + full stack trace to stderr

## Key Observations

1. **Consistent Exit Code**: All error cases return exit code 1
2. **Output Stream Routing**: All errors go to stderr, not stdout (clean separation)
3. **Error Verbosity**:
   - Unknown subcommand: Shows helpful command list
   - Missing argument: Shows usage hint
   - Invalid token: Shows full Ruby stack trace (verbose but informative)
4. **No Stderr Suppression**: Even with invalid format, tool doesn't silently fail

## Files Generated

- `invalid-subcommand.{exit,stdout,stderr}`
- `decode-no-arg.{exit,stdout,stderr}`
- `decode-invalid-token.{exit,stdout,stderr}`
