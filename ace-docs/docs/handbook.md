---
doc-type: user
title: ace-docs Handbook Catalog
purpose: Catalog of ace-docs workflows, skills, templates, and prompts
ace-docs:
  last-updated: 2026-04-01
  last-checked: 2026-04-01
---

# ace-docs Handbook Catalog

Reference for package-owned handbook resources in `ace-docs/handbook/`.

## Skills

- `as-docs-update`: update documentation with the main update workflow
- `as-docs-update-usage`: update usage docs from implementation
- `as-docs-squash-changelog`: merge multiple changelog entries before merge
- `as-docs-update-roadmap`: update roadmap progress and milestones
- `as-docs-maintain-adrs`: maintain ADR lifecycle (create/evolve/archive)
- `as-docs-update-blueprint`: update blueprint docs for current repo structure
- `as-docs-create-adr`: create a new ADR document
- `as-docs-update-tools`: update tool docs from implementation/tests
- `as-docs-create-api`: create API documentation
- `as-docs-create-user`: create user-facing documentation

## Workflow Instructions

All workflows are located under `ace-docs/handbook/workflow-instructions/docs/`:

- `update.wf.md`
- `update-usage.wf.md`
- `update-tools.wf.md`
- `update-roadmap.wf.md`
- `update-blueprint.wf.md`
- `update-context.wf.md`
- `create-user.wf.md`
- `create-api.wf.md`
- `create-adr.wf.md`
- `maintain-adrs.wf.md`
- `squash-changelog.wf.md`

Use them via `ace-bundle`, for example:

```bash
ace-bundle wfi://docs/update-usage
```

## Guides

Key guides in `ace-docs/handbook/guides/`:

- `documentation.g.md`
- `markdown-style.g.md`
- `documents-embedding.g.md`
- `documents-embedded-sync.g.md`
- language docs under `guides/documentation/` (`ruby.md`, `rust.md`, `typescript.md`)

## Prompts

Prompts in `ace-docs/handbook/prompts/`:

- `ace-change-analyzer.system.md`
- `ace-change-analyzer.user.md`
- `document-analysis.system.md`
- `document-analysis.md`
- `markdown-style.system.md`

## Templates

Templates in `ace-docs/handbook/templates/` include:

- project docs (`README`, architecture, vision, PRD, blueprint)
- decisions/ADR template
- roadmap templates
- code docs templates (`ruby-yard`, `javascript-jsdoc`)
- user docs template
