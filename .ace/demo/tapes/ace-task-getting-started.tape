# Description: Show ace-task create, show, subtask, and list workflow

# Tags: ace-task,docs,getting-started

Output .ace-local/demo/ace-task-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 480

Type "mise exec -- ace-task create 'Demo: onboarding task'"
Enter
Sleep 2s

Type "mise exec -- ace-task show 8q4.t.ums.2"
Enter
Sleep 2s

Type "mise exec -- ace-task create 'Demo: write outline' --child-of 8q4.t.ums.2"
Enter
Sleep 2s

Type "mise exec -- ace-task list --status pending"
Enter
Sleep 2s
