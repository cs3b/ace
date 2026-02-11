---
tc-id: TC-001
title: Dry Run Mode
---

## Objective

Verify that rewrite-history --dry-run shows what would be done without modifying git history.

## Steps

1. Run rewrite-history in dry run mode
   ```bash
   OUTPUT=$(ace-git-secrets rewrite-history --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code is 0 (dry run success)
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify dry run indication in output
   ```bash
   echo "$OUTPUT" | grep -qi "dry.run" && echo "PASS: Dry run mentioned" || echo "FAIL: No dry run indication"
   ```

4. Verify git history unchanged (original commit preserved)
   ```bash
   git log --oneline | grep -q "initial" && echo "PASS: Original commit preserved" || echo "FAIL: History was modified"
   ```

## Expected

- Exit code: 0
- Output shows "dry run" indication
- Git history unchanged
