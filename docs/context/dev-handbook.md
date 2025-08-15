# Dev-Handbook Context Definition
# This file defines what should be loaded for the dev-handbook submodule context

---
files:
  # Core documentation
  - dev-handbook/README.md
  - dev-handbook/workflow-instructions/README.md
  - dev-handbook/guides/README.md
  
  # Key workflow instructions
  - dev-handbook/workflow-instructions/load-project-context.wf.md
  - dev-handbook/workflow-instructions/update-blueprint.wf.md
  - dev-handbook/workflow-instructions/search-codebase.wf.md
  
  # Development guides
  - dev-handbook/guides/development/ruby-development.md
  - dev-handbook/guides/development/ai-agent-development.md
  - dev-handbook/guides/development/documentation-standards.md
  
  # Templates overview
  - dev-handbook/templates/README.md
  
  # Editor integrations
  - dev-handbook/zed/README.md

commands:
  - cmd: nav-tree --depth 2 dev-handbook/workflow-instructions
    label: "Available Workflow Instructions"
    
  - cmd: nav-tree --depth 2 dev-handbook/guides
    label: "Development Guides Structure"
    
  - cmd: git-status --repository dev-handbook
    label: "Dev-Handbook Git Status"

format: markdown-xml