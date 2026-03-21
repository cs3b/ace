---
doc-type: user
title: ace-sim
purpose: Documentation for ace-sim/README.md
ace-docs:
  last-updated: 2026-02-28
  last-checked: 2026-03-21
---

# ace-sim

Standalone file-chained simulation runner for ACE.

## Quick Start

```bash
ace-sim run \
  --preset validate-idea \
  --source path/to/source.md \
  --dry-run
```

Preset defaults can be overridden by explicit CLI flags (`--steps`, `--provider`, `--repeat`, etc.).

Optional final synthesis can generate a last-mile report:

```bash
ace-sim run \
  --preset validate-task \
  --source path/to/source.md
```

Built-in defaults:
- `validate-idea` uses `wfi://idea/review`
- `validate-task` uses `wfi://task/review`

See `docs/usage.md` for full usage.
