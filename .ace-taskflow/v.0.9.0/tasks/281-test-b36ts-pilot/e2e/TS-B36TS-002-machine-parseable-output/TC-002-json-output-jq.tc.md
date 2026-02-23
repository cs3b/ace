---
tc-id: TC-002
title: JSON Output Consumable by jq
mode: procedural
tags: [happy-path]
---

## Objective

Verify that ace-b36ts JSON output is valid JSON parseable by jq, and that specific fields can be extracted for use in downstream tooling.

## Steps

1. Generate JSON output and verify jq can parse it
   ```bash
   JSON_OUTPUT=$(ace-b36ts encode --json -q '2025-06-15 12:00:00 UTC')
   echo "Raw JSON: $JSON_OUTPUT"

   echo "$JSON_OUTPUT" | jq . > /dev/null 2>&1
   JQ_EXIT=$?

   [ $JQ_EXIT -eq 0 ] && echo "PASS: Valid JSON" || echo "FAIL: jq parse error (exit $JQ_EXIT)"
   ```

2. Extract the compact ID field using jq
   ```bash
   COMPACT_ID=$(echo "$JSON_OUTPUT" | jq -r '.compact_id // .id // .encoded')
   echo "Extracted ID: $COMPACT_ID"

   if [ -n "$COMPACT_ID" ] && [ "$COMPACT_ID" != "null" ]; then
     echo "PASS: ID field extractable"
   else
     echo "FAIL: Could not extract ID field"
   fi
   ```

3. Verify the extracted ID is usable (can be decoded)
   ```bash
   if [ -n "$COMPACT_ID" ] && [ "$COMPACT_ID" != "null" ]; then
     DECODED=$(ace-b36ts decode -q "$COMPACT_ID")
     echo "Decoded from jq-extracted ID: $DECODED"

     if echo "$DECODED" | grep -q "2025-06-15"; then
       echo "PASS: jq-extracted ID decodes correctly"
     else
       echo "FAIL: jq-extracted ID decode mismatch"
     fi
   else
     echo "SKIP: No ID to decode"
   fi
   ```

## Expected

- `ace-b36ts encode --json` produces output that `jq .` parses without error
- A compact ID field is extractable via jq
- The extracted ID is a valid ace-b36ts ID that decodes to the original date
