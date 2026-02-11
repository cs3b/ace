---
tc-id: TC-003
title: Mixed Rename, Delete, and Modify
---

## Objective

Verify that ace-git-commit correctly handles a combination of renamed, deleted, and modified files in a single operation. This consolidates rename and mixed-change scenarios.

## Steps

1. Rename old_name.rb using git mv
   ```bash
   git mv old_name.rb new_name.rb
   ```

2. Modify keeper.rb
   ```bash
   cat >> keeper.rb << 'EOF'

  def also_stay
    "Added method"
  end
EOF
   ```

3. Verify git status shows all changes
   ```bash
   git status --porcelain
   ```

4. Commit all changes using --only-staged for rename plus path for modification
   ```bash
   ace-git-commit new_name.rb old_name.rb keeper.rb -m "Rename old_name and update keeper"
   ```

5. Verify commit contains all changes
   ```bash
   git show --stat HEAD
   ```

6. Verify final state
   ```bash
   [ -f new_name.rb ] && echo "PASS: Renamed file exists" || echo "FAIL: Renamed file missing"
   [ ! -f old_name.rb ] && echo "PASS: Old file removed" || echo "FAIL: Old file still exists"
   grep -q "also_stay" keeper.rb && echo "PASS: Keeper modified" || echo "FAIL: Keeper not modified"
   ```

7. Verify working directory is clean
   ```bash
   UNCOMMITTED=$(git status --porcelain)
   [ -z "$UNCOMMITTED" ] && echo "PASS: All changes committed" || echo "FAIL: Uncommitted: $UNCOMMITTED"
   ```

## Expected

- Exit code: 0
- Commit contains rename (old_name.rb -> new_name.rb) and modification of keeper.rb
- new_name.rb exists with original content
- old_name.rb no longer exists
- keeper.rb contains the new method
- Working directory clean after commit
