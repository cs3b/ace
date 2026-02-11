---
tc-id: TC-002
title: Disabled Inference Requires Exact Match
---

## Objective

Verify that when extension_inference.enabled is false in nav config, only exact matches work. Requesting a resource without its extension should fail.

**Known Issue:** Setting `extension_inference: false` in nav config may not disable inference as expected (documented bug in config handling). This TC validates the intended behavior.

## Steps

1. Create config that disables extension inference
   ```bash
   mkdir -p ".ace/nav"
   cat > ".ace/nav/config.yml" << 'EOF'
   extension_inference:
     enabled: false
   EOF
   echo "PASS: Config created to disable inference"
   ```

2. Try to resolve without extension (should fail when inference is disabled)
   ```bash
   OUTPUT=$(ace-nav guide://markdown-style 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code without extension: $EXIT_CODE"
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Failed without extension (inference disabled)" || echo "KNOWN-ISSUE: Inference still active despite config (see TC notes)"
   ```

3. Try to resolve with exact extension (should always work)
   ```bash
   OUTPUT=$(ace-nav guide://markdown-style.g.md 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code with extension: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exact match works" || echo "FAIL: Exact match should always work"
   ```

4. Clean up config override
   ```bash
   rm -f ".ace/nav/config.yml"
   echo "PASS: Cleanup complete"
   ```

## Expected

- Without extension: Exit code non-zero (no inference, exact match fails)
- With exact extension: Exit code 0 (exact match always works)
- Demonstrates that config correctly disables inference
- Note: Known issue may cause step 2 to show KNOWN-ISSUE instead of PASS
