---
tc-id: TC-002
title: Deleted File Commit
---

## Objective

Verify that ace-git-commit correctly handles committing a deleted file. This validates the Task 220 fix for path validation issues when files no longer exist at their original location.

## Steps

1. Delete the file
   ```bash
   rm to_delete.rb
   ```

2. Verify git shows deletion
   ```bash
   git status --porcelain | grep -q "to_delete.rb" && echo "PASS: Git detects deletion" || echo "FAIL: Deletion not detected"
   ```

3. Commit the deletion
   ```bash
   ace-git-commit to_delete.rb -m "Remove deprecated ToDelete class"
   ```

4. Verify commit contains deletion
   ```bash
   git show --stat HEAD
   git log --oneline -1
   ```

5. Verify file no longer exists and is not tracked
   ```bash
   [ ! -f to_delete.rb ] && echo "PASS: File deleted" || echo "FAIL: File exists"
   git ls-files | grep -q "to_delete.rb" && echo "FAIL: Still tracked" || echo "PASS: Not tracked"
   ```

## Expected

- Exit code: 0
- Commit shows deletion of to_delete.rb
- File no longer exists in working directory
- File no longer tracked by git
