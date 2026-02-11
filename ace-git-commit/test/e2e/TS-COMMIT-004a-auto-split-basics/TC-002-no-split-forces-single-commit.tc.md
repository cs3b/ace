---
tc-id: TC-002
title: Force Single Commit with --no-split
---

## Objective

Verify that --no-split flag forces all changes into a single commit regardless of config scopes.

## Steps

1. Make changes in both packages
   ```bash
   cat >> pkg-a/service.rb << 'EOF'

  def another_method_a
    "Another method in package A"
  end
EOF

   cat >> pkg-b/service.rb << 'EOF'

  def another_method_b
    "Another method in package B"
  end
EOF

   git status --porcelain
   ```

2. Run ace-git-commit with --no-split
   ```bash
   ace-git-commit --no-split pkg-a/service.rb pkg-b/service.rb -m "Add methods to both services"
   ```

3. Verify single commit with both packages' files
   ```bash
   echo "=== Latest commit ==="
   git log --oneline -1
   git show --stat HEAD

   FILE_COUNT=$(git show --name-only --format="" HEAD | grep -c "service.rb")
   [ "$FILE_COUNT" -eq 2 ] && echo "PASS: Both service.rb files in one commit" || echo "FAIL: Expected 2 files, got $FILE_COUNT"
   ```

## Expected

- Exit code: 0
- Single commit created
- Commit contains files from both pkg-a and pkg-b
