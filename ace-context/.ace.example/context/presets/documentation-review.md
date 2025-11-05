---
description: Documentation review with organized sections
context:
  params:
    output: stdio
    format: markdown-xml
    max_size: 10485760
    timeout: 30
    embed_document_source: true

  sections:
    content:
      title: "Documentation Content"
      content_type: "files"
      priority: 1
      description: "Main documentation files being reviewed"
      files:
        - "README.md"
        - "docs/**/*.md"
        - "CHANGELOG.md"

    style:
      title: "Style Guidelines"
      content_type: "files"
      priority: 2
      description: "Documentation style and formatting guidelines"
      files:
        - "docs/STYLE_GUIDE.md"
        - "CONTRIBUTING.md"
        - ".markdownlint.json"

    structure:
      title: "Documentation Structure"
      content_type: "files"
      priority: 3
      description: "Documentation organization and navigation"
      files:
        - "docs/_navigation.yml"
        - "docs/_toc.yml"
        - "mkdocs.yml"

    examples:
      title: "Code Examples"
      content_type: "files"
      priority: 4
      description: "Example code and scripts in documentation"
      files:
        - "docs/examples/**/*"
        - "examples/**/*"

    validation:
      title: "Validation Results"
      content_type: "commands"
      priority: 5
      description: "Documentation validation and linting results"
      commands:
        - "markdownlint docs/**/*.md"
        - "bundle exec yard stats"
        - "find docs -name '*.md' -exec wc -l {} + | tail -1"
---

This preset is designed for reviewing documentation with sections covering content, style, structure, examples, and validation. It ensures comprehensive documentation review with organized sections for clarity.