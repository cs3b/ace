---
description: Default preset - includes README and basic docs
params:
  output: stdio
  embed_itself: true
  max_size: 1048576
  timeout: 30
context:
  files:
    - README.md
    - docs/blueprint.md
  exclude:
    - "**/node_modules/**"
    - "**/vendor/**"
    - "**/.git/**"
---

# Default Context

This is the default context preset for your project. It includes the README and blueprint documentation.

## Usage

```bash
ace-context default
ace-context default --output cache
```