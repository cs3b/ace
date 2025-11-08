---
description: Test auto-title generation
context:
  params:
    output: cache

  embed_document_source: true

  sections:
    project_overview:
      description: Overview of the project
      files:
        - README.md

    architecture:
      # No title - should be auto-generated
      files:
        - docs/architecture.md
---