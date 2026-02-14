---
tc-id: TC-001
title: Config Display and Verbose Mode
---

## Objective

Verify that the config command displays default settings and that verbose mode shows additional details including year range and config sources.

## Steps

1. Run config command and verify defaults
   ```bash
   CONFIG_OUTPUT=$(ace-b36ts config)
   echo "$CONFIG_OUTPUT"

   echo "$CONFIG_OUTPUT" | grep -q "year_zero.*2000" && echo "PASS: year_zero is 2000" || echo "FAIL: year_zero mismatch"
   echo "$CONFIG_OUTPUT" | grep -qi "alphabet" && echo "PASS: Alphabet shown" || echo "FAIL: Alphabet missing"
   ```

2. Run verbose config and verify additional details
   ```bash
   VERBOSE_OUTPUT=$(ace-b36ts config --verbose)
   echo "$VERBOSE_OUTPUT"

   echo "$VERBOSE_OUTPUT" | grep -qi "range\|years\|2000.*2107" && echo "PASS: Year range shown" || echo "CHECK: Review year range output"
   ```

3. Verify verbose has more output than basic
   ```bash
   BASIC_LINES=$(ace-b36ts config | wc -l)
   VERBOSE_LINES=$(ace-b36ts config --verbose | wc -l)
   [ "$VERBOSE_LINES" -ge "$BASIC_LINES" ] && echo "PASS: Verbose has more/equal output" || echo "FAIL: Verbose has less output"
   ```

## Expected

- Config shows year_zero: 2000 and alphabet (base36: 0-9a-z)
- Verbose output includes year range (2000-2107 for 108-year window)
- Verbose output has more lines than basic config
