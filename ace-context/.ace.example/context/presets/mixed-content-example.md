---
description: Example showing mixed content in a single section
context:
  params:
    output: stdio
    format: markdown-xml
    max_size: 10485760
    timeout: 30
    embed_document_source: true

  sections:
    review:
      title: "Complete Review"
      description: "Files, commands, diffs, and notes all in one section"
      files:
        - "src/**/*.js"
        - "README.md"
        - "package.json"
      commands:
        - "npm test"
        - "npm run lint"
      diffs:
        - "origin/main...HEAD"
      content: |
        This is a comprehensive review that includes:
        - Source files for code analysis
        - Test results for quality assurance
        - Recent changes for context
        - Manual notes and observations

        Focus on code quality, performance, and security.
---

This example demonstrates how a single section can contain multiple types of content (files, commands, diffs, and inline content) without requiring content_type or priority fields. The content will be processed in the order it appears in the section.