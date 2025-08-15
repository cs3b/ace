# Dev-Tools Context Definition
# This file defines what should be loaded for the dev-tools submodule context

---
files:
  # Core documentation
  - dev-tools/README.md
  - dev-tools/docs/tools.md
  - dev-tools/docs/development/DEVELOPMENT.md
  
  # Architecture and design
  - docs/architecture-tools.md
  - dev-tools/docs/decisions/*.md
  
  # Configuration files
  - dev-tools/coding_agent_tools.gemspec
  - dev-tools/Gemfile
  - dev-tools/.rubocop.yml
  
  # Key source directories overview
  - dev-tools/lib/coding_agent_tools.rb
  
  # Executable tools list
  - dev-tools/exe/README.md

commands:
  - cmd: nav-ls --long dev-tools/exe
    label: "Available CLI Tools"
    
  - cmd: nav-tree --depth 3 dev-tools/lib/coding_agent_tools
    label: "ATOM Architecture Structure"
    
  - cmd: git-status --repository dev-tools
    label: "Dev-Tools Git Status"

format: markdown-xml