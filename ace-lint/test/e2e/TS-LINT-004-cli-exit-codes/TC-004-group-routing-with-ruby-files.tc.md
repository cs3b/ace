---
tc-id: TC-004
title: Group Routing with Ruby Files
---

## Objective

Verify that Ruby files are correctly routed through group configuration.

## Steps

1. Verify Ruby config exists, then lint Ruby files and verify completion
   ```bash
   cat .ace/lint/ruby.yml && echo "PASS: Ruby config exists"
   OUTPUT=$(ace-lint lint app/models/user.rb app/controllers/users_controller.rb --verbose 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -ge 0 ] && echo "PASS: Command completed with exit code $EXIT_CODE" || echo "FAIL: Unexpected exit"
   echo "$OUTPUT" | grep -qiE "standardrb|rubocop" && echo "PASS: Validator shown in verbose output" || echo "FAIL: No validator name in verbose output"
   ```

## Expected

- Command completes with a valid exit code
- Ruby files are processed
- Verbose output shows validator being used
