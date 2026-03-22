# Description: Showcase ace-lint linting markdown and Ruby files with auto-fix
# Tags: ace-lint,docs,getting-started

Output ace-lint/docs/demo/ace-lint-getting-started.gif

Set FontSize 16
Set Width 1200
Set Height 700

# Scene 1: Lint multiple docs at once
Type 'ace-lint ace-lint/docs/getting-started.md ace-lint/docs/usage.md'
Enter
Sleep 3s

# Scene 2: Lint a Ruby file with auto-fix
Type 'ace-lint ace-lint/lib/ace/lint/version.rb --fix'
Enter
Sleep 3s

# Scene 3: Check configuration health
Type 'ace-lint --doctor'
Enter
Sleep 3s
