---
tc-id: TC-001
title: Auto-Split When Files Span Multiple Config Scopes
---

## Objective

Verify that ace-git-commit automatically creates separate commits when files span multiple configuration scopes.

## Steps

1. Make changes in both packages
   ```bash
   cat >> pkg-a/service.rb << 'EOF'

  def new_method_a
    "Added to package A"
  end
EOF

   cat >> pkg-b/service.rb << 'EOF'

  def new_method_b
    "Added to package B"
  end
EOF

   git status --porcelain
   ```

2. Run ace-git-commit with both files
   ```bash
   ace-git-commit pkg-a/service.rb pkg-b/service.rb -m "Add methods to services"
   ```

3. Verify two separate commits created
   ```bash
   echo "=== Recent commits ==="
   git log --oneline -3

   echo "=== Commit 1 (HEAD) ==="
   git show --stat HEAD
   echo "=== Commit 2 (HEAD~1) ==="
   git show --stat HEAD~1
   ```

4. Verify files in each commit belong to separate packages
   ```bash
   HEAD_PKG=$(git show --name-only --format="" HEAD | head -1 | cut -d/ -f1)
   PREV_PKG=$(git show --name-only --format="" HEAD~1 | head -1 | cut -d/ -f1)
   [ "$HEAD_PKG" != "$PREV_PKG" ] && echo "PASS: Commits contain different packages" || echo "FAIL: Same package in both commits"
   ```

## Expected

- Exit code: 0
- Two commits created (one per config scope)
- Each commit contains only files from one package
- Commit messages reflect the scope
