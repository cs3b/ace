---
doc-type: workflow
title: Start Assignment Workflow (Legacy Compatibility)
purpose: preserve compatibility for as-assign-start while routing to public assign/create + assign/drive flow
ace-docs:
  last-updated: 2026-03-18
  last-checked: 2026-03-21
---

# Start Assignment Workflow (Legacy Compatibility)

## Purpose

`assign/start` is retained as an orchestration compatibility layer for typed canonical skill examples.
It delegates to create/drive flows that compose steps from assign-capable canonical skills.

Primary public UX remains:
- `/as-assign-create ...`
- `/as-assign-drive <assignment-id>`

## Process

1. Parse incoming arguments.
2. If `--run` is provided, run create with run handoff enabled:

```bash
/as-assign-create $ARGUMENTS --run
```

3. Otherwise, run create without immediate handoff:

```bash
/as-assign-create $ARGUMENTS
```

4. If create succeeds and the caller requests explicit continuation, invoke:

```bash
/as-assign-drive <assignment-id>
```

## Success Criteria

- Preserves compatibility entrypoint for orchestration examples.
- Delegates behavior to `assign/create` and `assign/drive`.
- Does not redefine the public assignment flow.