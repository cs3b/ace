---
tc-id: TC-001
title: "Binary Smoke: Encode, Decode, Version"
mode: procedural
tags: [smoke]
---

## Objective

Verify that the ace-b36ts binary is executable, resolves its gem dependencies, and performs basic encode/decode/version operations through a real shell invocation.

## Steps

1. Verify the binary is executable and responds to --version
   ```bash
   ace-b36ts --version
   VERSION_EXIT=$?
   echo "Exit code: $VERSION_EXIT"
   [ $VERSION_EXIT -eq 0 ] && echo "PASS: --version exits 0" || echo "FAIL: --version exit $VERSION_EXIT"
   ```

2. Encode a known timestamp and verify output is base36
   ```bash
   ENCODED=$(ace-b36ts encode -q '2025-06-15 12:00:00 UTC')
   echo "Encoded: $ENCODED"

   if [[ "$ENCODED" =~ ^[0-9a-z]+$ ]]; then
     echo "PASS: Output is valid base36"
   else
     echo "FAIL: Output contains invalid characters"
   fi

   if [ -n "$ENCODED" ]; then
     echo "PASS: Non-empty output"
   else
     echo "FAIL: Empty output"
   fi
   ```

3. Decode the encoded value and verify date preservation
   ```bash
   DECODED=$(ace-b36ts decode -q "$ENCODED")
   echo "Decoded: $DECODED"

   if echo "$DECODED" | grep -q "2025-06-15"; then
     echo "PASS: Date preserved through roundtrip"
   else
     echo "FAIL: Date not preserved"
   fi
   ```

## Expected

- `ace-b36ts --version` exits with code 0 and produces output
- Encode produces a non-empty string of base36 characters (0-9a-z)
- Decode of the encoded value contains the original date (2025-06-15)
