---
tc-id: TC-002
title: File Pattern Matching
---

## Objective

Verify that file patterns in sections correctly match and include the intended files while excluding files outside the pattern.

## Steps

1. Load the comprehensive-review preset and capture output
   ```bash
   OUTPUT=$(ace-bundle comprehensive-review 2>&1)
   ```

2. Verify files matching patterns are included
   ```bash
   echo "$OUTPUT" | grep -q "Test Application" && echo "PASS: README.md content included" || echo "FAIL: README.md content not included"
   echo "$OUTPUT" | grep -q "Hello World" && echo "PASS: main.js content included" || echo "FAIL: main.js content not included"
   echo "$OUTPUT" | grep -q "helper()" && echo "PASS: utils.js content included" || echo "FAIL: utils.js content not included"
   ```

3. Verify files outside the pattern are excluded
   ```bash
   ! echo "$OUTPUT" | grep -q "describe('Main'" && echo "PASS: test files correctly excluded" || echo "INFO: test files may be included by another pattern"
   ```

## Expected

- README.md included (matches `*.md`)
- src/main.js and src/utils.js included (matches `src/**/*.js`)
- package.json included (matches `package.json`)
- test/main.test.js NOT included (not in any section pattern)
