---
name: as-invalid-integration-skill
description: Invalid skill with provider-specific integration metadata
# bundle: wfi://test/workflow
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Read
source: test
integration:
  targets: claude
  providers:
    claude:
      frontmatter: invalid
    unknown:
      frontmatter: {}
skill:
  kind: workflow
  execution:
    workflow: wfi://test/workflow
---

Body
