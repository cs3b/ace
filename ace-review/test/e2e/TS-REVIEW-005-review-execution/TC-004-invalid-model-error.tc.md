---
tc-id: TC-004
title: Error Handling for Invalid Model and Preset
---

## Objective

Verify that ace-review handles invalid model configurations and nonexistent presets gracefully with non-zero exit codes and error messages.

## Steps

1. Create preset with invalid model name
   ```bash
   cat > .ace/review/presets/invalid-model.yml << 'EOF'
   description: "Invalid model test"
   model: nonexistent:fake-model-xyz
   instructions:
     system: "Test"
     user: "Test"
   EOF
   ```

2. Run ace-review with invalid model
   ```bash
   OUTPUT_MODEL=$(ace-review review \
     --preset invalid-model \
     --subject "diff:HEAD~1" \
     --auto-execute 2>&1)
   EXIT_MODEL=$?

   echo "Invalid model test:"
   echo "Exit code: $EXIT_MODEL"
   echo "Output: $OUTPUT_MODEL"
   [ "$EXIT_MODEL" -ne 0 ] && echo "PASS: Non-zero exit for invalid model" || echo "FAIL: Expected non-zero exit"
   ```

3. Run ace-review with nonexistent preset
   ```bash
   OUTPUT_PRESET=$(ace-review review \
     --preset nonexistent-preset-xyz \
     --subject "diff:HEAD~1" \
     --auto-execute 2>&1)
   EXIT_PRESET=$?

   echo "Nonexistent preset test:"
   echo "Exit code: $EXIT_PRESET"
   echo "Output: $OUTPUT_PRESET"
   [ "$EXIT_PRESET" -ne 0 ] && echo "PASS: Non-zero exit for invalid preset" || echo "FAIL: Expected non-zero exit"
   echo "$OUTPUT_PRESET" | grep -qi "not found\|unknown\|error\|invalid" && \
     echo "PASS: Error message present" || \
     echo "FAIL: No clear error message"
   ```

## Expected

- Invalid model: non-zero exit code, error message about model issue
- Nonexistent preset: non-zero exit code, error message about preset not found
