# Description: Show ace-docs freshness status and single-file analyze flow
# Tags: ace-docs,docs,getting-started

Output ace-docs/docs/demo/ace-docs-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

Type 'ace-docs status --package ace-docs --needs-update'
Enter
Sleep 3s

Type 'ace-docs analyze ace-docs/README.md --since "2026-03-01"'
Enter
Sleep 4s
