# Goal 2 Verification - Status unknown provider error

## Expectation

`ace-handbook status --provider definitely-not-a-provider` fails with a non-zero exit and surfaces the unknown-provider contract to the user.

## Oracle Priority

1. User-visible error text in command output artifacts
2. Explicit non-zero exit artifact
3. Debug fallback captures only when primary artifacts are ambiguous

## PASS Criteria

- `results/tc/02/status-unknown.exit` is non-zero
- `results/tc/02/status-unknown.stderr` or `.stdout` includes `Unknown provider: definitely-not-a-provider`
