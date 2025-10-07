---
description: Project-wide context
context:
  params:
    output: cache
    max_size: 10485760
    timeout: 30
  embed_document_source: true
  files:
    - docs/what-do-we-build.md
    - docs/blueprint.md
    - docs/architecture.md
    - docs/decisions.md
    - docs/tools.md
  commands:
    - pwd
    - date
    - git status --short
    - task-manager recent --limit 3
    - task-manager next --limit 3
    - release-manager current
    - eza -R -1 -L 2 --git-ignore --absolute $PROJECT_ROOT_PATH
---

# Project Context

You are working on the Coding Agent Workflow Toolkit (Meta) - a comprehensive meta-repository that provides documentation and guidance for setting up AI-assisted development workflow systems.
