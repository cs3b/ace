# Description: Showcase ace-search content search, DWIM file search, and preset search
# Tags: ace-search,docs,getting-started

Output ace-search/docs/demo/ace-search-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: Content search (DWIM)
Type 'ace-search "TODO"'
Enter
Sleep 3s

# Scene 2: File search (DWIM glob detection)
Type 'ace-search "*.rb"'
Enter
Sleep 3s

# Scene 3: JSON output mode
Type 'ace-search "class" --json'
Enter
Sleep 3s
