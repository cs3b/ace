---
description: Minimal context - just README
params:
  output: stdio
  embed_itself: false
  max_size: 1048576
  timeout: 10
context:
  files:
    - README.md
---

# Minimal Context

This is the most minimal context preset - it only includes the project README file.

Useful for quick context loading when you just need basic project information.

## Usage

```bash
ace-context minimal
```