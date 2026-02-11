---
tc-id: TC-011
title: Current Branch Fallback When Parent Has No Worktree
---

## Objective

Verify target_branch uses current branch when parent task has no worktree metadata.

## Steps

1. Create a parent task without worktree metadata
   ```bash
   mkdir -p .ace-taskflow/v.test/tasks/777-parent-no-worktree

   cat > .ace-taskflow/v.test/tasks/777-parent-no-worktree/777.00-parent-no-worktree.s.md << 'EOF'
   ---
   id: v.test+task.777
   status: in_progress
   priority: medium
   ---

   # Parent Without Worktree

   This orchestrator has no worktree metadata.
   EOF

   cat > .ace-taskflow/v.test/tasks/777-parent-no-worktree/777.01-subtask.s.md << 'EOF'
   ---
   id: v.test+task.777.01
   status: draft
   priority: medium
   parent: v.test+task.777
   ---

   # Subtask Under Parent Without Worktree

   Feature subtask for testing current branch fallback.
   EOF

   git add .ace-taskflow/
   git commit -m "Add parent task without worktree and subtask" --quiet
   ```

2. Create a feature branch to simulate current working branch
   ```bash
   git checkout -b 777-feature-branch
   echo "Feature work" >> README.md
   git add README.md
   git commit -m "Feature work on 777" --quiet
   ```

3. Create worktree for subtask from the feature branch
   ```bash
   ace-git-worktree create --task 777.01 --no-push --no-pr --no-commit --no-auto-navigate --dry-run 2>&1
   ```

## Expected

- Dry-run output shows target_branch as "777-feature-branch" (current branch)
- NOT "main" as fallback
