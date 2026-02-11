---
tc-id: TC-002
title: Dry-Run Mode
---

## Objective

Verify that dry-run mode shows planned changes without actually committing.

## Steps

1. Make a modification and stage it
   ```bash
   cat >> helper.rb << 'EOF'

  def self.warn(msg)
    "[WARN] #{msg}"
  end
EOF
   git add helper.rb
   ```

2. Record current HEAD
   ```bash
   BEFORE_HEAD=$(git rev-parse HEAD)
   ```

3. Run dry-run
   ```bash
   ace-git-commit -n -m "Add warn helper method"
   ```

4. Verify HEAD unchanged
   ```bash
   AFTER_HEAD=$(git rev-parse HEAD)
   [ "$BEFORE_HEAD" = "$AFTER_HEAD" ] && echo "PASS: HEAD unchanged" || echo "FAIL: HEAD changed"
   ```

5. Verify changes still staged
   ```bash
   git diff --cached --name-only | grep -q "helper.rb" && echo "PASS: Changes still staged" || echo "FAIL: Changes not staged"
   ```

## Expected

- Exit code: 0
- Dry-run output shows what would be committed
- HEAD remains unchanged (no new commit)
- Changes remain staged
