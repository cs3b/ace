---
doc-type: user
title: ACE Config Delegation
purpose: Explain how ace-support-core delegates config CLI ownership to ace-support-config.
ace-docs:
  last-updated: 2026-03-31
  last-checked: 2026-03-31
---

# ACE Config Delegation

`ace-support-core` no longer ships a standalone config CLI. Configuration initialization, diffing, and listing are owned by `ace-support-config` via the `ace-config` command.

## Where Config CLI Lives

- Package: [`ace-support-config`](../../ace-support-config)
- Command: `ace-config`
- Usage reference: [`ace-support-config/docs/usage.md`](../../ace-support-config/docs/usage.md)

## Common Commands

```bash
# Initialize all ACE config defaults
ace-config init

# Preview initialization without writing files
ace-config init --dry-run

# Compare current config against defaults
ace-config diff --one-line

# Show available support package defaults
ace-config list
```

## Notes

- `ace-support-core` remains responsible for shared runtime/config primitives.
- `ace-support-config` owns config command behavior and user-facing config workflows.
