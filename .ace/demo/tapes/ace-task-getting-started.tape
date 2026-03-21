# Description: Showcase ace-task list, create, show, and archive workflow
# Tags: ace-task,docs,getting-started

Output .ace-local/demo/ace-task-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: List tasks and filter by status
Type "ace-task list"
Enter
Sleep 3s

Type "ace-task list --status pending"
Enter
Sleep 3s

# Scene 2: Create a task with all key options
Type "ace-task create 'Add health check endpoint' --priority high --tags ops,infra --status pending"
Enter
Sleep 3s

# Scene 3: Show task details and tree view
Type "ace-task show 8q4.t.ums.2"
Enter
Sleep 3s

Type "ace-task show 8q4.t.ums.2 --tree"
Enter
Sleep 3s

# Scene 4: Archive task
Type "ace-task update 8q4.t.ums.2 --set status=done --move-to archive"
Enter
Sleep 3s
