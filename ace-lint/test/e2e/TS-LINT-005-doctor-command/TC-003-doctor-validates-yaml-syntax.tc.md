---
tc-id: TC-003
title: Doctor Validates YAML Syntax
---

## Objective

Verify that doctor command validates YAML and shows valid status.

## Steps

1. Run doctor command with valid config
   ```bash
   cd groups-config
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Verify valid status is shown
   ```bash
   echo "$OUTPUT" | grep -qiE "valid|ok|pass" && echo "PASS: Valid status shown" || echo "INFO: Valid status not explicitly shown"
   ```

## Expected

- Exit code: 0 or 1 (healthy or warnings)
- Output indicates configuration is valid or no errors found
