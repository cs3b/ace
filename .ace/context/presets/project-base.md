---
description: Project-wide context
context:
  params:
    output: cache
    max_size: 10485760
    timeout: 30

  embed_document_source: true

  sections: 

    vision:
      title: Project Vision
      description: What do we Build
      files:
        - docs/what-do-we-build.md

    architecture:
      title: Architecture
      description: How do we build it
      files:
        - docs/architecture.md
        - docs/ace-gems.g.md
        
    structure:
      title: Project File Structure 
      description: How do we organize files
      files:
        - docs/blueprint.md
      commands:
        - eza -T -L 3 --git-ignore

  commands:
    - date
    - ace-git context
---

# Project Context

You are working on the Coding Agent Workflow Toolkit (Meta) - a comprehensive meta-repository that provides documentation and guidance for setting up AI-assisted development workflow systems.
