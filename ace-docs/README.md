# ace-docs

Keep documentation current by tracking freshness, detecting drift, and generating actionable update guidance.

[Getting Started](docs/getting-started.md) | [Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-docs demo](docs/demo/ace-docs-getting-started.gif)

`ace-docs` provides a practical maintenance loop for teams that need package docs to stay aligned with fast-moving code and workflow changes.

## Use Cases

**Prioritize documentation updates based on real drift** - identify which files are stale, what changed since last update, and where to focus first.

**Generate targeted update guidance for specific documents** - run LLM-assisted analysis to propose concrete doc revisions from current repository context.

**Catch cross-document inconsistencies before release** - validate metadata and compare documents to find conflicts across package documentation sets.

## Works With

- `ace-bundle` for context assembly and workflow loading.
- `ace-llm` for analysis and consistency checks.
- `ace-lint` for markdown validation and fix workflows.

## Features

- Frontmatter-based freshness tracking for markdown documentation.
- Document discovery across package roots and file globs.
- Targeted per-document change analysis for update planning.
- Cross-document consistency analysis before release.
- Metadata update workflows for single files or scoped sets.
- Syntax and semantic documentation validation support.

## Documentation

- [Getting Started](docs/getting-started.md)
- [Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-docs --help`

## Agent Skills

Package-owned canonical skills:

- `as-docs-update`
- `as-docs-update-usage`
- `as-docs-create-user`
- `as-docs-create-api`
- `as-docs-create-adr`
- `as-docs-maintain-adrs`
- `as-docs-update-blueprint`
- `as-docs-update-roadmap`
- `as-docs-update-tools`
- `as-docs-squash-changelog`

## Part of ACE

`ace-docs` is part of [ACE](../README.md) (Agentic Coding Environment).
