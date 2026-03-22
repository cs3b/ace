# Description: Preview task-aware worktree creation and listing
# Tags: docs,worktree

Output ace-git-worktree/docs/demo/ace-git-worktree-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 480

Type "cd $PWD"
Enter
Sleep 2s

Type "mise exec -- ace-git-worktree create --task 8q4.t.uno.1 --dry-run --no-commit --no-push --no-pr --no-auto-navigate"
Enter
Sleep 2s

Type "mise exec -- ace-git-worktree list --show-tasks"
Enter
Sleep 2s
