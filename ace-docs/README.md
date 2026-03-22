---
doc-type: user
title: ace-docs
purpose: Documentation for ace-docs/README.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-docs

Keep documentation current - track freshness, detect drift, and get LLM-powered suggestions.

![ace-docs demo](docs/demo/ace-docs-getting-started.gif)

## Why

Documentation gets stale when code and docs drift apart. `ace-docs` gives you a practical loop:

* find what changed since a document was last updated
* identify which docs need attention first
* run LLM-assisted analysis for concrete update suggestions
* catch cross-document conflicts before release

## Works With

* `ace-bundle` for context assembly
* `ace-llm` for analysis and consistency checks
* `ace-lint` for syntax validation

## Agent Skills

Package-owned canonical skills for docs workflows:

* `as-docs-update`
* `as-docs-update-usage`
* `as-docs-create-user`
* `as-docs-create-api`
* `as-docs-create-adr`
* `as-docs-maintain-adrs`
* `as-docs-update-blueprint`
* `as-docs-update-roadmap`
* `as-docs-update-tools`
* `as-docs-squash-changelog`

## Features

* frontmatter-based freshness tracking
* document discovery across packages or globs
* targeted change analysis per document
* cross-document consistency analysis
* metadata updates for one file or scoped sets
* syntax + semantic validation workflow

## Documentation

* [Getting Started](docs/getting-started.md)
* [CLI Usage Reference](docs/usage.md)
* [Handbook Catalog](docs/handbook.md)

## Part of ACE

`ace-docs` is part of [ACE][1]: CLI tools designed for developers and ready for agents.



[1]: https://github.com/cs3b/ace
