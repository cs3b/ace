# Goal 1 - Notes Reorganization Verification

## Expectations

1. `notes/inbox/` is empty after execution, proven by `results/tc/01/inbox-final.txt`.
2. `results/tc/01/archive-final.txt` proves exactly five markdown files exist under `notes/archive/` recursive tree.
3. Every archived filename starts with a lowercase base36 token followed by `-` (no fixed token-length assumption).
4. Archive path includes `year/month/week` segmentation (`YYYY/MM/WNN`).
5. Evidence cites concrete filesystem paths from `results/tc/01/archive-final.txt`.

## Verdict

- PASS: all expectations are met.
- FAIL: any expectation is not met.

Include concrete evidence paths in your verdict.
