# Description: Showcase ace-review presets, diff review, PR review, and feedback
# Tags: ace-review,docs,getting-started

Output docs/demo/ace-review-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: List available presets
Type "ace-review --list-presets"
Enter
Sleep 3s

# Scene 2: Review branch diff with preset
Type "ace-review --preset code --subject diff:origin/main..HEAD --dry-run"
Enter
Sleep 3s

# Scene 3: Review a PR
Type "ace-review --pr 251 --dry-run"
Enter
Sleep 3s

# Scene 4: List feedback items
Type "ace-review-feedback list --status draft"
Enter
Sleep 3s
