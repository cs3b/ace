---
tc-id: TC-003
title: Error Handling for Invalid Preset References
---

## Objective

Verify that circular dependencies, missing preset references, and nonexistent presets are detected and handled gracefully with non-zero exit codes.

## Steps

1. Attempt to use preset with circular dependency
   ```bash
   OUTPUT_CIRC=$(ace-review --preset preset_a --subject "test.rb" --dry-run 2>&1)
   EXIT_CIRC=$?
   echo "Circular dependency test:"
   echo "Exit code: $EXIT_CIRC"
   echo "Output: $OUTPUT_CIRC"
   [ "$EXIT_CIRC" -ne 0 ] && echo "PASS: Circular dependency rejected" || echo "FAIL: Expected non-zero exit code"
   ```

2. Attempt to use preset with missing reference
   ```bash
   OUTPUT_MISS=$(ace-review --preset broken --subject "test.rb" --dry-run 2>&1)
   EXIT_MISS=$?
   echo "Missing reference test:"
   echo "Exit code: $EXIT_MISS"
   echo "Output: $OUTPUT_MISS"
   [ "$EXIT_MISS" -ne 0 ] && echo "PASS: Missing reference rejected" || echo "FAIL: Expected non-zero exit code"
   ```

3. Attempt to use completely nonexistent preset
   ```bash
   OUTPUT_NONE=$(ace-review --preset totally_nonexistent --subject "test.rb" --dry-run 2>&1)
   EXIT_NONE=$?
   echo "Nonexistent preset test:"
   echo "Exit code: $EXIT_NONE"
   echo "Output: $OUTPUT_NONE"
   [ "$EXIT_NONE" -ne 0 ] && echo "PASS: Nonexistent preset rejected" || echo "FAIL: Expected non-zero exit code"
   ```

## Expected

- All three commands exit with non-zero status
- Circular dependency (preset_a -> preset_b -> preset_a) is detected
- Missing reference (broken -> nonexistent_base) is detected
- Nonexistent preset (totally_nonexistent) produces error message
