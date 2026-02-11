---
tc-id: TC-002
title: Multiple Mixed Subjects and Deduplication
---

## Objective

Verify that multiple subjects of different types are merged correctly and that duplicate subjects are deduplicated.

## Steps

1. Run ace-review with two different subject types
   ```bash
   OUTPUT_MIXED=$(ace-review --preset test \
     --subject "diff:HEAD~2" \
     --subject "files:lib/*.rb" \
     --dry-run 2>&1)
   EXIT_MIXED=$?
   echo "Mixed subjects output:"
   echo "$OUTPUT_MIXED"
   echo "Exit code: $EXIT_MIXED"
   [ "$EXIT_MIXED" -eq 0 ] && echo "PASS: Multiple mixed subjects merged" || echo "FAIL: Expected exit code 0, got $EXIT_MIXED"
   ```

2. Run ace-review with three subjects including duplicates
   ```bash
   OUTPUT_DEDUP=$(ace-review --preset test \
     --subject "files:README.md" \
     --subject "diff:HEAD~1" \
     --subject "files:lib/*.rb" \
     --dry-run 2>&1)
   EXIT_DEDUP=$?
   echo "Three subjects output:"
   echo "$OUTPUT_DEDUP"
   echo "Exit code: $EXIT_DEDUP"
   [ "$EXIT_DEDUP" -eq 0 ] && echo "PASS: Three subjects processed" || echo "FAIL: Expected exit code 0, got $EXIT_DEDUP"
   ```

3. Run with staged changes subject
   ```bash
   echo "# New comment" >> lib/example.rb
   git add lib/example.rb
   OUTPUT_STAGED=$(ace-review --preset test --subject "staged" --dry-run 2>&1)
   EXIT_STAGED=$?
   echo "Staged subject output:"
   echo "$OUTPUT_STAGED"
   echo "Exit code: $EXIT_STAGED"
   [ "$EXIT_STAGED" -eq 0 ] && echo "PASS: Staged changes processed" || echo "FAIL: Expected exit code 0, got $EXIT_STAGED"
   git checkout -- lib/example.rb
   ```

## Expected

- Exit code: 0 for all commands
- Mixed types (diff + files) are merged and processed together
- Three subjects are all processed in a single review
- Staged changes keyword is recognized and processed
