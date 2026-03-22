# Description: Showcase ace-overseer worktree dashboard with progress bars and PR status
# Tags: ace-overseer, docs, getting-started

Output docs/demo/ace-overseer-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: Show the worktree dashboard — progress bars, PR status, failure counts
Type "ace-overseer status"
Enter
Sleep 6s

# Scene 2: Show available commands
Type "ace-overseer --help"
Enter
Sleep 4s

# Scene 3: Show work-on options for launching task worktrees
Type "ace-overseer work-on --help"
Enter
Sleep 5s
