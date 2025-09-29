---
description: Project-wide context
params:
  output: cache              # Output to cache directory
  embed_itself: true         # Include this preset file in output
  max_size: 10485760        # 10MB max size
  timeout: 30               # 30 second timeout for commands
context:
  files:
    # Core documentation files
    - docs/what-do-we-build.md
    - docs/blueprint.md
    - docs/architecture.md
    - docs/decisions.md
    - docs/tools.md
    - README.md
    - CHANGELOG.md
  commands:
    # System information
    - pwd
    - date

    # Git status
    - git status --short
    - git branch --show-current
    - git log -1 --oneline

    # Project structure
    - ls -la

    # Optional task management (if available)
    - task-manager recent --limit 3
    - task-manager next --limit 3
    - release-manager current
---

# Project Context

This preset loads comprehensive project context including documentation, current git state, and project structure. Customize the files and commands sections for your specific project needs.