---
doc-type: user
title: ace-idea Handbook Catalog
purpose: Catalog of ace-idea workflows and skills
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-idea Handbook Catalog

Reference for package-owned handbook resources in `ace-idea/handbook/`.

## Skills

| Skill | What it does |
|------|---------------|
| `as-idea-capture` | Capture a development idea into a structured idea file |
| `as-idea-capture-features` | Document application features from a user perspective |
| `as-idea-review` | Review idea clarity, scope, and readiness before task creation |

## Workflow Instructions

| Protocol Path | Purpose | Invoked by |
|------|---------|------------|
| `wfi://idea/capture` | Capture raw ideas from text or clipboard and store them as structured idea files | `as-idea-capture` |
| `wfi://idea/capture-features` | Document application features from a user perspective | `as-idea-capture-features` |
| `wfi://idea/review` | Critically review ideas for clarity, impact, and execution readiness | `as-idea-review` |
| `wfi://idea/prioritize` | Prioritize and align ideas with current project architecture | Direct via `ace-bundle` |

## Agents

* None currently shipped in this package.

## Related Docs

* [Getting Started](getting-started.md)
* [CLI Usage Reference](usage.md)
* Load workflows directly with `mise exec -- ace-bundle wfi://idea/capture`
