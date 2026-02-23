# Goal 5: Output Routing — Summary

## Verbosity Modes Tested

All tests encode the same date: `2020-01-01` → Token: `6o0000`

### Mode 1: Default (no flags)
- **Stdout**: `6o0000` (the encoded token)
- **Stderr**: (empty)

### Mode 2: Quiet (`--quiet`)
- **Stdout**: `6o0000`
- **Stderr**: (empty)
- **Behavior**: Same as default in this case (suppresses "non-essential" output, but encode output is essential)

### Mode 3: Verbose (`--verbose`)
- **Stdout**: `6o0000` (the encoded token)
- **Stderr**: Config information
  ```
  Config: args=2020-01-01 b36ts.alphabet=0123456789abcdefghijklmnopqrstuvwxyz b36ts.default_format=2sec b36ts.year_zero=2000 verbose=true
  ```

### Mode 4: Debug (`--debug`)
- **Stdout**: `6o0000`
- **Stderr**: (empty or minimal)

## Key Observations

1. **Primary Output (stdout)**: Encoded token always goes to stdout, regardless of verbosity
2. **Diagnostic Output (stderr)**: Verbose mode adds configuration info to stderr
3. **Clean Stream Separation**: Encode result always on stdout, diagnostics on stderr
4. **Quiet Mode**: Doesn't reduce output in this case (--quiet may only apply to certain operations)
5. **Debug Mode**: Appears to not add output for this simple operation

## Files Generated

- `default.{stdout,stderr}`
- `quiet.{stdout,stderr}`
- `verbose.{stdout,stderr}`
- `debug.{stdout,stderr}`

**Pattern Confirmed**: Output streams are properly separated; primary output to stdout, diagnostics to stderr.
