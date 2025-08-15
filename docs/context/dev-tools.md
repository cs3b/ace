# Dev-Tools Context Configuration

This context file focuses specifically on the dev-tools submodule, demonstrating how to create focused context configurations for specific parts of the project.

## Purpose

This configuration extracts context specifically related to the Ruby gem development in the dev-tools submodule.

<context-tool-config>
files:
  - dev-tools/lib/coding_agent_tools/**/*.rb
  - dev-tools/spec/**/*_spec.rb
  - dev-tools/Gemfile
  - dev-tools/coding_agent_tools.gemspec
  - dev-tools/README.md

commands:
  - find dev-tools/lib -name "*.rb" | head -20
  - bundle exec rspec --dry-run | head -10
  - cd dev-tools && bundle list --name-only | head -15

format: markdown-xml
embed_document_source: false
</context-tool-config>

## Usage

```bash
# Load dev-tools specific context
context docs/context/dev-tools.md

# Since embed_document_source: false, this will output only the processed context
# without this document content
```

## Key Features

- **Focused scope** - Only includes Ruby gem related files
- **Test awareness** - Includes spec files to understand test structure  
- **Dependency tracking** - Shows Gemfile and gemspec for dependency context
- **Command context** - Executes relevant commands to show current state

This configuration is useful when working specifically on Ruby gem development tasks.