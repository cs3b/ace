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
  - git-status --short
  - task-manager recent --limit 5
  - task-manager next --limit 5
  - release-manager current
  - git ls-files
  - git -C dev-handbook ls-files -- workflow-instructions
  - git -C dev-tools ls-files -- lib
</context-tool-config>
