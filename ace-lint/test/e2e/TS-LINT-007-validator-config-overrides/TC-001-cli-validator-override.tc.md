---
tc-id: TC-001
title: CLI Validator Override
---

## Objective

Verify that the validator can be explicitly specified via CLI.

## Steps

1. Force RuboCop and StandardRB explicitly via --validators flag
   ```bash
   echo "=== Force RuboCop ==="
   ace-lint lint --validators rubocop valid.rb
   echo "=== Force StandardRB ==="
   ace-lint lint --validators standardrb valid.rb
   ```

## Expected

- First command uses RuboCop (verify from output)
- Second command uses StandardRB (verify from output)
- Both produce valid lint results
