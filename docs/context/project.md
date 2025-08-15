# Project Context Definition
# This file defines what should be loaded for the main project context

---
files:
  # Core project documentation
  - docs/what-do-we-build.md
  - docs/architecture.md
  - docs/blueprint.md
  - docs/tools.md
  
  # System architecture details
  - docs/architecture-tools.md
  
  # Project configuration
  - CLAUDE.md
  - README.md
  - package.json
  
  # Submodule documentation (if accessible)
  - dev-handbook/README.md
  - dev-tools/README.md
  - dev-taskflow/README.md

commands:
  - cmd: git-status
    label: "Current Git Status"
    
  - cmd: nav-tree --depth 2
    label: "Project Structure Overview"
    
  - cmd: task-manager next
    label: "Next Actionable Task"
    
  - cmd: release-manager current
    label: "Current Release Information"

format: markdown-xml