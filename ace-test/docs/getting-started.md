---
doc-type: user
title: Getting Started with ace-test
purpose: Documentation for ace-test/docs/getting-started.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-test

`ace-test` is the testing knowledge base package for ACE.

## Prerequisites

- Ruby knowledge for your target stack
- `ace-bundle` installed in your environment

## Installation

In the monorepo:

```bash
bundle install
```

The package is already part of the repository and used through protocol access.

## Accessing your first testing guide

Open the quick reference to orient yourself before deep links:

```bash
ace-bundle guide://quick-reference
```

## Browsing guides and workflows

```bash
ace-bundle guide://testing-philosophy
ace-bundle guide://test-organization
ace-bundle guide://mocking-patterns
ace-bundle wfi://test/plan
ace-bundle wfi://test/create-cases
ace-bundle wfi://test/fix
```

## Using test workflows

- Start with planning: `wfi://test/plan`
- Create cases and tasks for missing coverage: `wfi://test/create-cases`
- Improve coverage systematically: `wfi://test/improve-coverage`
- Fix failures with repeatable workflows: `wfi://test/fix`
- Verify suite quality: `wfi://test/verify-suite`

## Performance targets overview

The package includes performance guidance in handbook guides:

- Layer-aware expectations
- Slow-test detection and cleanup flows
- Practical tradeoffs for speed vs. confidence

Refer to guide sections in `handbook/guides/` for exact targets.

## Next steps

- Review [Usage Guide](usage.md)
- Browse [Handbook Reference](handbook.md)
- Continue directly with a workflow, for example `ace-bundle wfi://test/plan`
