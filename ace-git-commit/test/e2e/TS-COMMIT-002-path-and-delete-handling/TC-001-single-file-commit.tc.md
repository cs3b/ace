---
tc-id: TC-001
title: Single File Commit
---

## Objective

Verify that specifying a single file only commits that file, leaving others untracked.

## Steps

1. Create a new untracked file
   ```bash
   cat > extra.rb << 'EOF'
# frozen_string_literal: true

class Extra
  def bonus
    "Extra functionality"
  end
end
EOF
   ```

2. Commit only main.rb (already tracked, modify it first)
   ```bash
   cat >> main.rb << 'EOF'

# Updated entry point
EOF
   ace-git-commit main.rb -m "Update main entry point"
   ```

3. Verify only main.rb was committed
   ```bash
   git show --stat HEAD
   ```

4. Verify extra.rb remains untracked
   ```bash
   git status --porcelain | grep -q "extra.rb" && echo "PASS: extra.rb still untracked" || echo "FAIL: extra.rb not found in status"
   ```

5. Clean up untracked file for subsequent test cases
   ```bash
   rm -f extra.rb
   ```

## Expected

- Exit code: 0
- Commit contains only main.rb
- extra.rb remains untracked (before cleanup)
- Commit message is "Update main entry point"
