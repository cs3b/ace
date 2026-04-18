# Goal 1 Verification - Sync provider projection

## Expectation

`ace-handbook sync --provider pi` exits successfully, reports sync summary lines, and leaves provider projection output in `.pi/skills`.

## Oracle Priority

1. User-visible sync output (`results/tc/01/sync-pi.stdout`)
2. Explicit command exit artifact (`results/tc/01/sync-pi.exit`)
3. Debug fallback captures (`results/tc/01/sync-pi.stderr`) only when primary artifacts are ambiguous

## PASS Criteria

- `results/tc/01/sync-pi.exit` is `0`
- `results/tc/01/sync-pi.stdout` includes `synced pi -> .pi/skills`
