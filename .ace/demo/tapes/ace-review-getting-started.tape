# Description: Show ace-review preset-based PR and diff review workflow
# Tags: ace-review,docs,getting-started

Output .ace-local/demo/ace-review-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 480

Type "mise exec -- ace-review --list-presets"
Enter
Sleep 2s

Type "mise exec -- ace-review --preset code --subject diff:origin/main..HEAD --dry-run"
Enter
Sleep 2s

Type "mise exec -- ace-review --pr 123 --preset code-pr --dry-run"
Enter
Sleep 2s
