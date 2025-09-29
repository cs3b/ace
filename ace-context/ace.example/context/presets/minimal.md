---
description: Minimal context for quick operations
params:
  output: stdio             # Output to standard output
  embed_itself: false       # Don't include this file
  max_size: 1048576        # 1MB max size
  timeout: 10              # 10 second timeout
context:
  files:
    # Just the essentials
    - README.md
    - docs/blueprint.md
  commands:
    # Basic info only
    - pwd
    - git status --short
---

# Minimal Context

This preset loads only essential project information for quick context loading. Ideal for rapid iterations and simple queries.