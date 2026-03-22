# Description: Showcase ace-overseer command surface and worktree dashboard
# Tags: ace-overseer, docs, getting-started

Output docs/demo/ace-overseer-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: Show command surface
Type "ace-overseer --help"
Enter
Sleep 3s

# Scene 2: Show active worktrees dashboard
Type "ace-overseer status"
Enter
Sleep 3s

# Scene 3: Show JSON output format
Type "ace-overseer status --format json"
Enter
Sleep 3s
