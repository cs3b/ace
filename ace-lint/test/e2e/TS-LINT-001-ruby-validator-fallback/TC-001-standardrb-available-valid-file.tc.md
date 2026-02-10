---
tc-id: TC-001
title: StandardRB Available - Valid File
---

## Objective

Verify that valid Ruby code passes linting when StandardRB is available.

## Steps

1. Lint the valid file
   ```bash
   ace-lint lint valid.rb
   ```

## Expected

- Exit code: 0
- Output indicates no issues found
- StandardRB was used (check output or logs)
