---
description: Project-wide context
context:
  params:
    output: cache
    max_size: 81920
    timeout: 30
  embed_document_source: true
  files:
    - docs/vision.md
    - docs/blueprint.md
    - docs/architecture.md
    - docs/ace-gems.g.md
    - docs/decisions.md
    - docs/tools.md
    - docs/testing-patterns.md
  commands:
    - pwd
    - date
    - ace-git status
    - git status --short
    - ace-taskflow status
    - ace-taskflow tasks next --limit 1
    - eza -R -1 -L 3 -git-ignore --absolute $PROJECT_ROOT_PATH
---

# Project Context

You are working on the Coding Agent Workflow Toolkit (Meta) - a comprehensive meta-repository that provides documentation and guidance for setting up AI-assisted development workflow systems.
