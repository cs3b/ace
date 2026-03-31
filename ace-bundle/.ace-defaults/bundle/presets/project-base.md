---
description: Lightweight project starter preset for first-run onboarding
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
      content: |
        TODO: Add a one-paragraph project overview and current priorities.
        Move this to docs/vision.md later if desired.

    structure:
      title: Project Structure
      content: |
        TODO: Describe the top-level folders and where core logic lives.
        Move this to docs/blueprint.md once project docs exist.

    quick_status:
      title: Quick Status
      compressor_mode: exact
      commands:
        - pwd
        - date

    starter_guidance:
      title: Starter Guidance
      content: |
        TODO: Add concise onboarding notes for contributors.
        Replace placeholders with your project's goals and current priorities.
---

# Project Context

Use this lightweight preset as a starting point for new projects.
Expand sections as your team documentation grows.
