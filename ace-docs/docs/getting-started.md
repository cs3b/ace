---
doc-type: user
title: ace-docs Getting Started
purpose: Tutorial for ace-docs first-run workflow
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-docs

This tutorial walks through a first-use flow: track a document, check freshness, analyze drift, and run consistency
checks.

## Prerequisites

- Ruby 3.2+
- `ace-docs` installed
- `ace-llm` installed for LLM-backed commands (`analyze`, `analyze-consistency --semantic` workflows)
- A git repository with markdown docs

## Installation

```bash
gem install ace-docs
```

## 1. Add Frontmatter to Your First Document

Create or update a markdown file:

```yaml
---
doc-type: guide
title: Project Overview
purpose: Explain system goals and key flows
ace-docs:
  last-updated: 2026-03-22
  subject:
    diff:
      paths:
        - "lib/**/*.rb"
        - "docs/**/*.md"
---
```

## 2. Check Document Status

```bash
ace-docs status
ace-docs status --needs-update
```

Use `--package` or `--glob` when you want to scope output.

## 3. Analyze Changes with LLM

Pick a specific document and analyze changes since last update:

```bash
ace-docs analyze docs/architecture.md
```

Use `--since` to override the time window:

```bash
ace-docs analyze docs/architecture.md --since "2026-03-01"
```

## 4. Run Consistency Checks

Check terminology, duplicates, and version mismatches across docs:

```bash
ace-docs analyze-consistency
```

Target one area when needed:

```bash
ace-docs analyze-consistency --terminology
ace-docs analyze-consistency --duplicates --threshold 80
```

## Common Commands

| Goal | Command |
|------|---------|
| Show tracked docs | `ace-docs status` |
| Show only stale docs | `ace-docs status --needs-update` |
| Analyze one file | `ace-docs analyze FILE` |
| Analyze consistency | `ace-docs analyze-consistency` |
| Update metadata | `ace-docs update FILE --set last-updated=today` |
| Validate docs | `ace-docs validate` |

## Next Steps

- Run `ace-docs validate` in CI before merge
- Use `ace-docs analyze-consistency --strict` for release checks
- Add package-scoped status checks in docs maintenance workflows
- Build multi-subject analysis patterns for large docs sets

## Package Test Commands

```bash
ace-test ace-docs
ace-test ace-docs feat
ace-test ace-docs all
ace-test-e2e ace-docs
```
