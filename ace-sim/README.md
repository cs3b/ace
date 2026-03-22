---
doc-type: user
title: ace-sim
purpose: Landing page for ace-sim
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-sim

`ace-sim` runs **multi-provider simulation chains** over project tasks and ideas so teams can compare perspectives before deciding on a direction.

![ace-sim getting started](docs/demo/ace-sim-run.gif)

Multi-provider LLM simulations for validating ideas and reviewing tasks

## Why

`ace-sim` gives you structured, repeatable simulation runs when you need:
- Alternative model reasoning before committing to a plan
- A review lens on tasks before work starts
- Confidence that assumptions were tested across multiple providers

## Works With

- `ace-sim` simulation presets (`validate-idea`, `validate-task`)
- `ace-bundle` for source collection and context assembly
- `ace-llm` for step-level provider execution
- `ace-review` for applying synthesized recommendations
- `ace-task` and `ace-assign` workflows

## Agent Skills

- `as-sim-run`

## Features

- Multi-provider chains with repeatable execution and provider overrides
- Preset-driven behavior for idea validation and task review
- File-chained steps (`draft`, `plan`, `work`) for progressive refinement
- Final synthesis aggregation into actionable suggestions and revised source

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Catalog](docs/handbook.md)
- `ace-sim` command reference in this package documentation

## Part of ACE

`ace-sim` is part of [ACE](../README.md): practical tooling for humans and AI working together.

## Additional Context

- Runs are deterministic and stored under `.ace-local/sim/simulations`.
- Each run can be repeated with different providers and repeat counts.
- Presets can be reused across team workflows and CI.
- Agent-friendly output is designed for both manual review and automation.
