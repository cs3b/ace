---
description: Simple example of preset-in-section for basic project setup
context:
  params:
    output: stdio
    format: markdown-xml
    max_size: 5242880
    timeout: 15

  sections:
    project_files:
      title: "Project Source Code"
      description: "Core project files and configuration"
      presets:
        - "base"
      files:
        - "src/**/*.rb"
        - "lib/**/*.rb"
        - "config/**/*.yml"
      content: |
        Main application source code and configuration files.
        This combines the base preset with project-specific files.

    testing:
      title: "Testing Setup"
      description: "Test framework and test files"
      presets:
        - "testing"
      commands:
        - "bundle exec rspec --format documentation"
        - "bundle exec rubocop"
      content: |
        Test execution and code quality checks for the project.

---

This example shows a simple use case where:

1. **project_files section** combines the "base" preset with additional project files
2. **testing section** includes the "testing" preset plus custom test commands
3. Each section maintains its own focus while leveraging preset content

The presets provide common functionality while allowing section-specific customization.