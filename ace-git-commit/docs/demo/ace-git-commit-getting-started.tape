# Description: Showcase ace-git-commit with intention, specific files, and dry-run
# Tags: ace-git-commit,docs,getting-started

Output docs/demo/ace-git-commit-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: Show current changes
Type "git status --short"
Enter
Sleep 3s

# Scene 2: Basic dry-run commit
Type "ace-git-commit --dry-run"
Enter
Sleep 3s

# Scene 3: With intention context
Type "ace-git-commit -i 'fix auth bug' --dry-run"
Enter
Sleep 3s

# Scene 4: Specific files only
Type "ace-git-commit ace-review/README.md --dry-run"
Enter
Sleep 3s

# Scene 5: Only staged files
Type "ace-git-commit --only-staged --dry-run"
Enter
Sleep 3s
