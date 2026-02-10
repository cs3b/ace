---
tc-id: TC-005
title: Batch Linting
---

## Objective

Verify that ace-lint can process multiple files in a directory.

## Steps

1. Lint all files in batch directory
   ```bash
   ace-lint lint batch/*.rb
   ```

## Expected

- All three files are processed
- Results shown for each file
- Summary of total issues
