---
tc-id: TC-003
title: Simple Preset Loading
---

## Objective

Verify that simple presets without sections (top-level commands and files) are loaded correctly.

## Steps

1. Load the security-scanning preset
   ```bash
   OUTPUT=$(ace-bundle security-scanning 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

2. Verify command output is captured
   ```bash
   echo "$OUTPUT" | grep -q "Security audit complete" && echo "PASS: Security audit command found" || echo "FAIL: Security audit not found"
   ```

3. Verify files are included
   ```bash
   echo "$OUTPUT" | grep -qE "main.js|utils.js|package.json" && echo "PASS: JS/JSON files found" || echo "FAIL: Expected files not found"
   ```

## Expected

- Exit code: 0
- Command output "Security audit complete" captured
- Files matching `**/*.js` and `package*.json` included in output
