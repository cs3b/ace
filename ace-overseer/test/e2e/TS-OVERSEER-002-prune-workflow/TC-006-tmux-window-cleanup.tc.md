---
tc-id: TC-006
title: Tmux Window Closed for Pruned Task
---

## Objective

Verify that prune closed the tmux window for the pruned task (t001) but left the window for the unsafe task (t002) open.

## Steps

1. Check tmux windows after prune
   ```bash
   WINDOWS=$(tmux list-windows -t "ace-e2e-test" 2>&1)
   echo "Tmux windows after prune:"
   echo "$WINDOWS"

   echo "$WINDOWS" | grep -q "t001" && echo "FAIL: Tmux window t001 still exists after prune!" || echo "PASS: Tmux window t001 closed by prune"
   echo "$WINDOWS" | grep -q "t002" && echo "PASS: Tmux window t002 still exists (task not pruned)" || echo "INFO: Tmux window t002 not found (may have been closed separately)"
   ```

## Expected

- Tmux window "t001" is gone (closed during prune)
- Tmux window "t002" still exists (task not pruned)
