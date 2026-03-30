---
description: Project-wide context starter preset for generic projects
bundle:
  params:
    output: cache
    max_size: 10485760
    timeout: 30
    compressor_mode: agent
  embed_document_source: true
  sections:
    vision:
      title: Project Vision
      files:
        - docs/vision.md

    architecture:
      title: System Architecture
      files:
        - docs/architecture.md
        - docs/decisions.md
        - docs/blueprint.md

    project_status:
      title: Project Status
      compressor_mode: exact
      commands:
        - pwd
        - date
        - ls -1

    onboarding_notes:
      title: Onboarding Notes
      content: |
        TODO: Replace this preset body text with your project-specific onboarding guidance.
        Include your architecture highlights, coding standards, and ownership boundaries.
---

# Project Context

You are working in a project that uses ACE tooling.
Treat this as starter scaffolding and customize it for your codebase.
