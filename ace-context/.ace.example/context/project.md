---
description: Full project documentation and status
params:
  output: cache
  embed_itself: true
  max_size: 10485760
  timeout: 30
context:
  files:
    - README.md
    - docs/**/*.md
    - CLAUDE.md
    - "*.gemspec"
  commands:
    - git status --short
    - git branch --show-current
    - date
  exclude:
    - "**/node_modules/**"
    - "**/vendor/**"
    - "**/.git/**"
    - "**/test/**"
    - "**/spec/**"
---

# Project Context

This preset loads comprehensive project documentation including all markdown files in docs/, the main README, and project configuration files.

It also includes git status and current branch information to provide context about the current state of the repository.

## Usage

```bash
ace-context project                  # Uses default cache output
ace-context project --output stdio   # Override to output to terminal
```

## Customization

Copy this file to `.ace/context/project.md` and modify the files, commands, and exclude patterns to match your project's needs.