---
description: "Comprehensive review with mixed content"
bundle:
  params:
    output: stdio
    format: markdown-xml
    timeout: 30

  sections:
    comprehensive:
      title: "Complete Review"
      description: "Files, commands, diffs, and analysis"
      files:
        - "*.md"
        - "package.json"
        - "src/**/*.js"
      commands:
        - "echo 'Running tests...' && exit 0"
        - "echo 'Linting passed' && exit 0"
        - "echo 'No security issues found' && exit 0"
      content: |
        This comprehensive review includes:

        1. **Code Quality**: Style, patterns, maintainability
        2. **Security**: Vulnerabilities and dependencies
        3. **Testing**: Coverage and test results
        4. **Performance**: Potential bottlenecks

        Focus on security and performance aspects.
---
# Comprehensive Review Preset

This preset demonstrates mixed content within sections, combining files,
commands, and analysis content in a single structured section.
