---
description: Project context
bundle:
  params:
    # output: cache
    max_size: 81920
    timeout: 30
    compressor_mode: agent

  embed_document_source: true
  sections:

    vision:
      title: Project Vision
      files:
        - docs/vision.md

    architecture:
      title: System Architecture
      files:
        - docs/architecture.md
        - docs/decisions.md
        - docs/ace-gems.g.md

    structure:
      title: Project Structure
      files:
        - docs/blueprint.md

    governance_ops:
      title: Ops Governance
      files:
        - docs/tools.md

    project_status:
      title: Project Status
      compressor_mode: exact
      commands:
        - pwd
        - date
        - ace-git status
        - ace-task status
---

# Project Context

You are working on Coding Agent Workflow Toolkit (Meta), a repo of docs and guidance for AI-assisted development workflows.
