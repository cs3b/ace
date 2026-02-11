---
tc-id: TC-001
title: Commit All Changes with Explicit Message
---

## Objective

Verify that ace-git-commit commits all staged changes with a provided message (bypasses LLM).

## Steps

1. Create new files and stage them
   ```bash
   cat >> app.rb << 'EOF'

  def stop
    puts "Stopping #{@name}"
  end
EOF
   cat >> helper.rb << 'EOF'

  def self.debug(msg)
    "[DEBUG] #{msg}"
  end
EOF
   git add app.rb helper.rb
   ```

2. Commit with explicit message using -m flag
   ```bash
   ace-git-commit -m "Add stop and debug methods"
   ```

3. Verify commit was created
   ```bash
   git log --oneline -1
   git show --stat HEAD
   ```

4. Verify working directory is clean
   ```bash
   UNCOMMITTED=$(git status --porcelain)
   [ -z "$UNCOMMITTED" ] && echo "PASS: Working directory clean" || echo "FAIL: Uncommitted changes: $UNCOMMITTED"
   ```

## Expected

- Exit code: 0
- Commit created with message "Add stop and debug methods"
- Both app.rb and helper.rb appear in commit
- Working directory shows no pending changes
