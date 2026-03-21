# Description: Show ace-git-commit getting-started workflow from staged changes to generated message

# Tags: ace-git-commit,docs,getting-started

Output .ace-local/demo/ace-git-commit-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 480

Type "git status --short"
Enter
Sleep 2s

Type "mise exec -- ace-git-commit --dry-run"
Enter
Sleep 2s

Type "mise exec -- ace-git-commit -i 'fix auth bug' --dry-run"
Enter
Sleep 2s

Type "mise exec -- ace-git-commit --only-staged --dry-run"
Enter
Sleep 2s
