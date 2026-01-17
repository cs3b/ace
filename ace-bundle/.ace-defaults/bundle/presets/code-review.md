---
description: Code review context with section-based organization
bundle:
  params:
    output: stdio
    format: markdown-xml
    max_size: 10485760
    timeout: 30
    embed_document_source: true

  sections:
    focus:
      title: "Files Under Review"
      description: "Source files that are being reviewed"
      files:
        - "src/**/*.rb"
        - "lib/**/*.rb"
        - "test/**/*.rb"
        - "spec/**/*.rb"

    style:
      title: "Style Guidelines"
      description: "Style and coding standards"
      files:
        - ".rubocop.yml"
        - "docs/CODING_STANDARDS.md"
        - "CONTRIBUTING.md"

    diff:
      title: "Recent Changes"
      description: "Recent changes in the codebase"
      ranges:
        - "origin/main...HEAD"

    tests:
      title: "Test Results"
      description: "Current test results"
      commands:
        - "bundle exec rspec --format documentation"
        - "bundle exec rubocop"
        - "bundle exec rubycritical"

    bundle:
      title: "Project Context"
      description: "Project information and status"
      commands:
        - "git log --oneline origin/main..HEAD"
        - "git status --short"
        - "pwd"
        - "ruby -v"
---

This preset provides a comprehensive code review context organized into logical sections. Each section contains specific information relevant for code review:

- **Focus**: The actual source files being reviewed
- **Style**: Coding standards and style guidelines
- **Diff**: Recent changes that prompted the review
- **Tests**: Current test results and quality checks
- **Context**: Project information and git status

The sections are prioritized to show the most important information first, with XML-style tags for structured processing.