---
tc-id: TC-{NNN}
title: {Test Case Title}
mode: procedural
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

<!--
Inline goal-mode variant:

---
tc-id: TC-{NNN}
title: {Test Case Title}
mode: goal
---

## Objective
{Outcome to achieve}

## Available Tools
- {tool-1}
- {tool-2}

## Success Criteria
- [ ] {criterion 1}
- [ ] {criterion 2}

Do not include a "## Steps" section in mode: goal.
-->
