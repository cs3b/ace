---
description: Development context extending base with code files
bundle:
  presets:
    - base
  files:
    - docs/architecture.md
    - docs/blueprint.md
  commands:
    - git status --short
    - git branch --show-current
---

# Development Context

This preset extends the base context with additional development-specific files and git status information.
