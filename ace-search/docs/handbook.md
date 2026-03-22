---
doc-type: user
title: ace-search Handbook Reference
purpose: Documentation for ace-search/docs/handbook.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-search Handbook Reference

Skills and workflow instructions shipped with `ace-search`.

## Skills

| Skill | What it does |
|-------|-------------|
| `as-search-run` | SEARCH code patterns and files with intelligent discovery |
| `as-search-research` | RESEARCH codebases through planned multi-search analysis |
| `as-search-feature-research` | RESEARCH feature gaps and implementation patterns |

## Workflow Instructions

| Protocol Path | Purpose | Invoked by |
|--------------|---------|------------|
| `wfi://search/run` | Execute single search workflows with DWIM mode and filtering | `as-search-run` |
| `wfi://search/research` | Plan and execute multi-step codebase research | `as-search-research` |
| `wfi://search/feature-research` | Analyze feature capabilities and implementation patterns | `as-search-feature-research` |

## Source Paths

- Skills: `ace-search/handbook/skills/`
- Workflows: `ace-search/handbook/workflow-instructions/search/`

## Related Docs

- [Getting Started](getting-started.md)
- [Usage Guide](usage.md)
- Runtime discovery: `ace-nav wfi://search/*`
