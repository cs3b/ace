---
doc-type: user
title: ace-assign Handbook Reference
purpose: Skill and workflow catalog shipped with ace-assign.
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-assign Handbook Reference

Canonical skills and workflow instructions bundled with `ace-assign`.

## Skills

| Skill | What it does |
|-------|---------------|
| `as-assign-add-task` | Add a work-on-task subtree into a running assignment batch parent |
| `as-assign-compose` | Compose a tailored assignment from catalog steps and composition rules |
| `as-assign-create` | Create assignments from public workflow, with optional handoff to drive |
| `as-assign-drive` | Drive active assignment execution step-by-step |
| `as-assign-prepare` | Legacy/internal helper for preparing job specs |
| `as-assign-run-in-batches` | Build repeated-item fan-out assignments from templates and item lists |
| `as-assign-start` | Legacy compatibility wrapper routing create then drive |

## Workflow Instructions

| Protocol Path | Purpose | Invoked by |
|---------------|---------|------------|
| `wfi://assign/add-task` | Insert a task subtree into a running assignment using `ace-assign add --yaml` | `as-assign-add-task` |
| `wfi://assign/compose` | Compose assignment definitions from cataloged steps | `as-assign-compose` |
| `wfi://assign/create` | Create assignment and initialize queue from config | `as-assign-create` |
| `wfi://assign/drive` | Execute active assignment loop with status/finish/fail transitions | `as-assign-drive` |
| `wfi://assign/prepare` | Legacy preset/informal instructions to job spec preparation | `as-assign-prepare` |
| `wfi://assign/run-in-batches` | Generate a repeated-item batch assignment | `as-assign-run-in-batches` |
| `wfi://assign/start` | Legacy orchestration entrypoint for create+drive | `as-assign-start` |

## Guides

| Guide | Purpose |
|-------|---------|
| `fork-context.g.md` | Fork subtree design, delegation boundaries, and recovery practices |
