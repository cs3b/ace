# Description: Showcase ace-assign workflow queue with tree status and assignment listing
# Tags: ace-assign, docs, getting-started

Output docs/demo/ace-assign-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: List all assignments at a glance
Type "ace-assign list"
Enter
Sleep 4s

# Scene 2: Show the full workflow tree with step status, nesting, and fork indicators
Type "ace-assign status"
Enter
Sleep 8s

# Scene 3: Show flat view for quick scanning of all step files
Type "ace-assign status --flat"
Enter
Sleep 5s
