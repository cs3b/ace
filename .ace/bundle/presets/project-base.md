---
description: Project-wide context
bundle:
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
        - docs/vision.md

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
    - date
    - ace-git status
---

# Project Context

You are working on the Coding Agent Workflow Toolkit (Meta) - a comprehensive meta-repository that provides documentation and guidance for setting up AI-assisted development workflow systems.
