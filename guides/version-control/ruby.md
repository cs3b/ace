# Ruby Version Control Examples

This file provides Ruby-specific examples and considerations related to the main [Version Control Guide](../version-control.md).

*   **.gitignore:** Ensure standard Ruby/Rails files are ignored (e.g., `log/*`, `tmp/*`, `.bundle/`, `coverage/`, `.env`). Tools like [gitignore.io](https://www.toptal.com/developers/gitignore) can generate good starting points.
*   **Pre-commit Hooks:** Use tools like `overcommit` or `lefthook` to run linters (`RuboCop`), formatters (`RuboCop -a`), and tests (`RSpec`, `Minitest`) before committing.
*   **Dependency Locking:** Always commit `Gemfile.lock` to ensure consistent dependencies across environments.
*   **Branching Strategy:** Standard Git workflows (like Gitflow or GitHub Flow) apply. No Ruby-specific branching requirements.

```yaml
# Example .overcommit.yml snippet
PreCommit:
  RuboCop:
    enabled: true
    command: ['bundle', 'exec', 'rubocop', '--parallel']
  RSpec:
    enabled: true
    command: ['bundle', 'exec', 'rspec']

CommitMsg:
  CapitalizedSubject:
    enabled: true
  EmptyMessage:
    enabled: true
  TextWidth:
    enabled: true
```

```gitignore
# Example additions to .gitignore for a Ruby project
/.bundle
/log/*
!/log/.keep
/tmp/*
!/tmp/.keep
/coverage/
*.gem
.env*
```
