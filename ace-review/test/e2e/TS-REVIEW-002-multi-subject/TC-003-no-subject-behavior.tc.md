---
tc-id: TC-003
title: No Subject and Empty Subject Handling
---

## Objective

Verify that running ace-review without any subject or with empty subjects is handled gracefully.

## Steps

1. Run ace-review with no subject
   ```bash
   OUTPUT_NONE=$(ace-review --preset test --dry-run 2>&1)
   EXIT_NONE=$?
   echo "No subject output:"
   echo "Exit code: $EXIT_NONE"
   echo "$OUTPUT_NONE"
   echo "INFO: No-subject behavior depends on preset - exit code $EXIT_NONE is acceptable"
   ```

2. Run ace-review with an empty subject followed by a valid one
   ```bash
   OUTPUT_EMPTY=$(ace-review --preset test \
     --subject "" \
     --subject "diff:HEAD~1" \
     --dry-run 2>&1)
   EXIT_EMPTY=$?
   echo "Empty + valid subject output:"
   echo "$OUTPUT_EMPTY"
   echo "Exit code: $EXIT_EMPTY"
   [ "$EXIT_EMPTY" -eq 0 ] && echo "PASS: Empty subject filtered, valid subject processed" || echo "FAIL: Expected exit code 0, got $EXIT_EMPTY"
   ```

## Expected

- No-subject: either succeeds with default or fails with clear message (both acceptable)
- Empty + valid: exit code 0, empty subject filtered out, valid subject processed
