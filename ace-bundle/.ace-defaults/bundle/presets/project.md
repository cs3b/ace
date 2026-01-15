---
description: Project-wide context
context:
  params:
    output: cache
    max_size: 10485760
    timeout: 30
  embed_document_source: true
  files:
    - docs/vision.md
    - docs/blueprint.md
    - docs/architecture.md
    - docs/decisions.md
    - docs/tools.md
  commands:
    - pwd
    - date
    - git status --short
    - ace-taskflow recent --limit 3
    - ace-taskflow next --limit 3
    - eza -R -1 -L 2 --git-ignore --absolute $PROJECT_ROOT_PATH
  # Optional: Include diffs (delegated to ace-git for consistent filtering)
  # diffs:
  #   - origin/main...HEAD
  # Or use ranges with options (respects global .ace/diff/config.yml):
  # diff:
  #   ranges:
  #     - origin/main...HEAD
  #   paths:
  #     - "lib/**/*.rb"
---

# Project Context

You are working on the Coding Agent Workflow Toolkit (Meta) - a comprehensive meta-repository that provides documentation and guidance for setting up AI-assisted development workflow systems.
