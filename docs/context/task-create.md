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
  - dev-handbook/workflow-instructions/draft-task.wf.md
  - dev-handbook/workflow-instructions/plan-task.wf.md

commands:
  - git-status --short
  - release-manager current
  - task-manager recent --limit 5
  - task-manager create --help
</context-tool-config>
