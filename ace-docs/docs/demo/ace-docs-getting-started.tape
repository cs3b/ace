# Description: Showcase ace-docs tracking document freshness and analyzing changes
# Tags: ace-docs,docs,getting-started

Output ace-docs/docs/demo/ace-docs-getting-started.gif

Set FontSize 16
Set Width 1200
Set Height 700

# Scene 1: See all tracked documents with freshness status
Type 'ace-docs status --package ace-docs'
Enter
Sleep 4s

# Scene 2: Analyze what changed since a document was last updated
Type 'ace-docs analyze ace-docs/README.md --since "2026-03-01"'
Enter
Sleep 8s
