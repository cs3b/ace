# Description: Showcase ace-assign create, status, scoped status, finish, and queue progress
# Tags: ace-assign,docs,getting-started

Output docs/demo/ace-assign-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: Show command surface
Type "ace-assign --help"
Enter
Sleep 3s

# Scene 2: Show active scoped subtree status in this repo
Type "ace-assign status --assignment 8ql0mx@010.01"
Enter
Sleep 3s

# Scene 3: Show flat status output
Type "ace-assign status --assignment 8ql0mx@010.01 --flat"
Enter
Sleep 3s

# Scene 4: Show listing of assignments
Type "ace-assign list"
Enter
Sleep 3s

# Scene 5: Show assignment selection command
Type "ace-assign select 8ql0mx"
Enter
Sleep 3s
