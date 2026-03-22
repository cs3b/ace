# Description: Showcase ace-search DWIM detection, scoped search, and file discovery
# Tags: ace-search,docs,getting-started

Output ace-search/docs/demo/ace-search-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: Content search — DWIM auto-detects a regex pattern
Type 'ace-search "VERSION" ace-search/'
Enter
Sleep 3s

# Scene 2: File search — DWIM auto-detects a glob pattern
Type 'ace-search "*.md" ace-docs/docs/'
Enter
Sleep 3s

# Scene 3: Git-aware — search only changed files
Type 'ace-search "README" --changed'
Enter
Sleep 3s
