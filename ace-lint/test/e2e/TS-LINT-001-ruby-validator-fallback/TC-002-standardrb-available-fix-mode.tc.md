---
tc-id: TC-002
title: StandardRB Available - Fix Mode Detects and Fixes Style Issues
---

## Objective

Verify that StandardRB detects and fixes style issues in `--fix` mode.

## Steps

1. Create a copy of the style issues file
   ```bash
   cp style_issues.rb style_issues_copy.rb
   ```

2. Run lint with --fix on the copy
   ```bash
   ace-lint lint --fix style_issues_copy.rb
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

3. Verify the file was modified by comparing to original
   ```bash
   diff style_issues.rb style_issues_copy.rb
   ```

## Expected

- Exit code: 0 (fix mode auto-corrects and succeeds)
- diff shows differences between original and copy (style fixes applied)
- StandardRB was used (check output or logs)
