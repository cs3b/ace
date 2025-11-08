---
description: Example demonstrating preset-in-section functionality for project context creation
context:
  params:
    output: stdio
    format: markdown-xml
    max_size: 10485760
    timeout: 30
    embed_document_source: true

  sections:
    project_context:
      title: "Complete Project Context"
      description: "Project context created by combining multiple presets within a single section"
      presets:
        - "base"
        - "development"
        - "testing"
      content: |
        This section demonstrates how presets can be combined within a single section to create comprehensive project context. The files, commands, and configurations from all referenced presets are merged together with the local content.

        This approach enables modular project setup where you can mix and match different preset components:

        - **base**: Core project files and configuration
        - **development**: Development tools and build commands
        - **testing**: Test frameworks and validation commands

        The presets are loaded with full composition support, so they can themselves reference other presets, creating a powerful hierarchical context system.

    documentation:
      title: "Documentation & Guides"
      description: "Project documentation and usage guides"
      presets:
        - "documentation-review"
      files:
        - "docs/**/*.md"
        - "README.md"
        - "CHANGELOG.md"
      content: |
        Project documentation including API guides, user manuals, and development setup instructions.

    deployment:
      title: "Deployment & Operations"
      description: "Deployment configuration and operational procedures"
      files:
        - "deploy/**/*"
        - "docker-compose.yml"
        - ".env.example"
      commands:
        - "docker-compose config"
        - "kubectl apply -f k8s/ --dry-run=client"
      content: |
        Deployment configurations and operational procedures for production environments.

---

This preset demonstrates the new preset-in-section functionality that allows you to:

1. **Combine multiple presets within a section** - Reference multiple presets that will be merged together
2. **Mix presets with local content** - Add files, commands, and content alongside preset references
3. **Create modular project contexts** - Build complex project setups from reusable preset components
4. **Maintain section organization** - Keep related content organized in logical sections

### Usage

```bash
# Load this preset with section-based context
ace-context load project-context

# The sections will be processed with all preset content merged in
```

### Key Features

- **Preset Composition**: Full support for preset composition within sections
- **Content Merging**: Files, commands, diffs, and content from presets are merged intelligently
- **Deduplication**: Duplicate files and commands are automatically removed
- **Error Handling**: Clear error messages for missing or invalid preset references
- **Backward Compatibility**: Works alongside existing section and preset functionality