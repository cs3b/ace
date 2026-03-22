---
doc-type: user
title: ace-demo Handbook Reference
purpose: Skills and workflow catalog shipped with ace-demo
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-demo Handbook Reference

Reference for package-owned skill and workflow assets.

## Skills

| Skill | What it does |
|-------|--------------|
| `as-demo-record` | Record terminal demos from presets, files, or inline commands |
| `as-demo-create` | Generate VHS tape files from shell command sequences |

## Workflows

| Protocol Path | Purpose | Invoked by |
|--------------|---------|------------|
| `wfi://demo/record` | Capture a demo from tape or inline command input | `as-demo-record` |
| `wfi://demo/create` | Generate a new tape from shell command input | `as-demo-create` |

## Related Docs

- [Getting Started](getting-started.md)
- [Usage Reference](usage.md)
- Command help: `ace-demo --help`
