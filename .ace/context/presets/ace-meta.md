---
description: ace-meta project context
params:
  output: stdio
  embed_itself: true
  max_size: 10485760
  timeout: 30
context:
  files:
    - README.md
    - docs/architecture.md
    - docs/what-do-we-build.md
    - docs/blueprint.md
    - dev-taskflow/current/*/roadmap.md
  exclude:
    - "**/node_modules/**"
    - "**/vendor/**"
---

# ACE Meta Context

This preset loads the core ACE meta-repository documentation including architecture, what we build, and current roadmap.