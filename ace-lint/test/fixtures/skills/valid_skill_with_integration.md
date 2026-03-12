---
name: as-valid-integration-skill
description: Valid skill with provider-specific integration metadata
# bundle: wfi://test/workflow
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Read
source: test
integration:
  targets:
    - claude
    - codex
  providers:
    claude:
      frontmatter:
        context: fork
        model: haiku
        prompt: "Use Claude"
    codex:
      frontmatter:
        context: fork
        model: gpt-5.3-codex-spark
skill:
  kind: workflow
  execution:
    workflow: wfi://test/workflow
---

Body
