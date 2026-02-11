---
tc-id: TC-002
title: Split Output Modes (Path-Only and JSON)
---

## Objective

Verify that --path-only produces a single-line path suitable for shell scripts and that --json produces valid JSON with expected keys.

## Steps

1. Verify path-only is a single usable line
   ```bash
   TS="2025-06-15 14:32:45"
   PATH_ONLY=$(ace-timestamp encode --split month,week --path-only -q "$TS")
   echo "Path: $PATH_ONLY"

   LINE_COUNT=$(echo "$PATH_ONLY" | wc -l | tr -d ' ')
   [ "$LINE_COUNT" -eq 1 ] && echo "PASS: Single line" || echo "FAIL: Multiple lines ($LINE_COUNT)"

   mkdir -p "$PATH_ONLY"
   [ -d "$PATH_ONLY" ] && echo "PASS: Valid directory path" || echo "FAIL: Invalid path"
   rm -rf "$(echo "$PATH_ONLY" | cut -d/ -f1)"
   ```

2. Verify JSON output structure
   ```bash
   JSON_OUT=$(ace-timestamp encode --split month,week,day --json -q "$TS")
   echo "$JSON_OUT"

   echo "$JSON_OUT" | jq . > /dev/null 2>&1 && echo "PASS: Valid JSON" || echo "FAIL: Invalid JSON"
   echo "$JSON_OUT" | jq -e '.month' > /dev/null && echo "PASS: Has month key" || echo "FAIL: Missing month"
   echo "$JSON_OUT" | jq -e '.path' > /dev/null && echo "PASS: Has path key" || echo "FAIL: Missing path"
   ```

3. Verify decode from path with different separators
   ```bash
   SLASH_PATH=$(ace-timestamp encode --split month,week,day --path-only -q "$TS")
   COLON_PATH=$(echo "$SLASH_PATH" | tr '/' ':')

   DECODED_SLASH=$(ace-timestamp decode -q "$SLASH_PATH")
   DECODED_COLON=$(ace-timestamp decode -q "$COLON_PATH")

   echo "Slash decoded: $DECODED_SLASH"
   echo "Colon decoded: $DECODED_COLON"
   [ "$DECODED_SLASH" = "$DECODED_COLON" ] && echo "PASS: Both separators decode same" || echo "FAIL: Different results"
   ```

## Expected

- Path-only output is a single line with forward-slash separators
- Path can be used directly in mkdir/file operations
- JSON output is valid and contains month, path, and full keys
- Forward-slash and colon path separators both decode to the same timestamp
