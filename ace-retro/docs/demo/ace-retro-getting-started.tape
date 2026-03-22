# Description: Showcase ace-retro creation, listing, and filtering
# Tags: ace-retro, docs, getting-started

Output docs/demo/ace-retro-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: Show command surface
Type "ace-retro --help"
Enter
Sleep 3s

# Scene 2: Preview creating a retro (dry-run)
Type "ace-retro create 'Sprint Review' --type standard --tags sprint,team --dry-run"
Enter
Sleep 3s

# Scene 3: List active retros
Type "ace-retro list"
Enter
Sleep 3s

# Scene 4: List archived retros with filter
Type "ace-retro list --in archive --status done"
Enter
Sleep 3s
