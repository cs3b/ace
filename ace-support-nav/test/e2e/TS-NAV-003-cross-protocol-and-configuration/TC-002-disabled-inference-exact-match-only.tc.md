---
tc-id: TC-002
title: Disabled Inference Still Allows Primary Extension Matching
---

## Objective

Verify that when extension_inference.enabled is false, primary extension matching
still works (guide://markdown-style resolves via configured extensions), but the
inference fallback path is disabled. Both exact and extension-matched URIs should resolve.

Note: "extension inference" controls only the fallback path (find_resources_with_inference),
not the primary extension matching (find_resources_with_extensions). Resources with
configured extensions (e.g., .g.md for guide://) always resolve.

## Steps

1. Create config that disables extension inference fallback
   ```bash
   mkdir -p ".ace/nav"
   cat > ".ace/nav/config.yml" << 'EOF'
   extension_inference:
     enabled: false
   EOF
   echo "PASS: Config created to disable inference"
   ```

2. Resolve without extension (works via primary extension matching)
   ```bash
   OUTPUT=$(ace-nav guide://markdown-style 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code without extension: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Resolved via primary extension matching" || echo "FAIL: Primary extension matching should always work"
   ```

3. Resolve with exact extension (should always work)
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

- Without extension: Exit code 0 (resolved via primary extension matching, not inference)
- With exact extension: Exit code 0 (exact match always works)
- Disabling inference only affects the fallback path, not primary extension matching
