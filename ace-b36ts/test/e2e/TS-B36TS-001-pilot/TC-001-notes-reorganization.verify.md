# Goal 1 - Notes Reorganization Verification

## Expectations
1. `notes/inbox/` is empty after execution.
2. Exactly five markdown files exist under `notes/archive/` recursive tree.
3. Every archived filename starts with a 3-character lowercase base36 token followed by `-`.
4. Archive path includes `year/month/week` segmentation (`YYYY/MM/WNN`).

## Verdict
- PASS: all expectations are met.
- FAIL: any expectation is not met.

Include concrete evidence paths in your verdict.
