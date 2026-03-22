# Description: Showcase ace-lint markdown linting, Ruby auto-fix, and doctor diagnostics
# Tags: ace-lint,docs,getting-started

Output ace-lint/docs/demo/ace-lint-getting-started.gif

Set FontSize 16
Set Width 1200
Set Height 700

# Scene 1: Lint a markdown file
Type 'ace-lint ace-lint/README.md'
Enter
Sleep 3s

# Scene 2: Lint Ruby with auto-fix
Type 'ace-lint ace-lint/lib/ace/lint/version.rb --type ruby --fix'
Enter
Sleep 3s

# Scene 3: Run doctor diagnostics
Type 'ace-lint --doctor'
Enter
Sleep 3s
