---
tc-id: TC-{NNN}
title: {Test Case Title}
---

## Objective

{What this test case verifies - 1-2 sentences}

## Steps

1. {Step description}
   ```bash
   {command to execute}
   ```

2. {Verification step}
   ```bash
   [ "$EXIT_CODE" -eq {expected} ] && echo "PASS: {description}" || echo "FAIL: {details}"
   ```

## Expected

- {Expected outcome 1}
- {Expected outcome 2}
