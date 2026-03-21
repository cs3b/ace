# Description: Showcase ace-bundle preset loading, listing, and protocol usage
# Tags: ace-bundle,docs,getting-started

Output .ace-local/demo/ace-bundle-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: Load project context
Type "ace-bundle project"
Enter
Sleep 3s

# Scene 2: List available presets
Type "ace-bundle --list"
Enter
Sleep 3s

# Scene 3: Load workflow via protocol
Type "ace-bundle wfi://task/plan"
Enter
Sleep 3s

# Scene 4: Inspect resolved config
Type "ace-bundle project --inspect-config"
Enter
Sleep 3s
