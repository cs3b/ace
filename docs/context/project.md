--- 
description: project wide context
--- 

# Project Context

You are working on the Coding Agent Workflow Toolkit (Meta) - a comprehensive meta-repository that provides documentation and guidance for setting up AI-assisted development workflow systems.

## Context

<context-tool-config>
embed_document_source: true
files:
  - docs/what-do-we-build.md
  - docs/architecture.md
  - docs/decisions.md
  - docs/blueprint.md
  - docs/tools.md

commands:

- git status --short
- task-manager recent --limit 3
- task-manager next --limit 3
- release-manager current
- eza -R -1 -L 2 --git-ignore $PROJECT_ROOT_PATH
- date
</context-tool-config>
