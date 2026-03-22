# Description: Showcase ace-retro creation, listing, show, and health checks
# Tags: ace-retro, docs, getting-started

Output docs/demo/ace-retro-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: Preview creating a retro without writing (dry-run)
Type "ace-retro create 'Sprint Review' --type standard --tags sprint,team --dry-run"
Enter
Sleep 4s

# Scene 2: List active retros with tags and task references
Type "ace-retro list"
Enter
Sleep 6s

# Scene 3: Show a retro with full content (learnings, action items)
Type "ace-retro show 8ql2t1"
Enter
Sleep 8s

# Scene 4: Run health checks across all retros
Type "ace-retro doctor"
Enter
Sleep 5s
