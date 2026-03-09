---
description: Project context
bundle:
  params:
    output: cache
    max_size: 10485760
    timeout: 30
    compressor_source_scope: merged
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
        - docs/ace-gems.g.md
        
    structure:
      title: Project Structure
      files:
        - docs/blueprint.md

    project_status:
      title: Project Status
      compressor_mode: exact
      commands:
        - pwd
        - date
        - ace-git status
---

# Project Context

You are working on Coding Agent Workflow Toolkit (Meta), a repo of docs and guidance for AI-assisted development workflows.
