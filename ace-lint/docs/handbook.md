---
doc-type: user
title: ace-lint Handbook Reference
purpose: Documentation for ace-lint/docs/handbook.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-lint Handbook Reference

Skills and workflow instructions shipped with `ace-lint`.

## Skills

| Skill | What it does |
|-------|-------------|
| `as-lint-run` | Run `ace-lint` with configured files/options and optional auto-fix |
| `as-lint-process-report` | Process lint report output and prepare manual follow-up work |
| `as-lint-fix-issue-from` | Apply focused fixes from reported lint findings |

## Workflow Instructions

| Protocol Path | Purpose | Invoked by |
|--------------|---------|------------|
| `wfi://lint/run` | Execute linting with project/user/default config cascade | `as-lint-run` |
| `wfi://lint/process-report` | Analyze lint report content and derive fix tasks | `as-lint-process-report` |

## Source Paths

- Skills: `ace-lint/handbook/skills/`
- Workflows: `ace-lint/handbook/workflow-instructions/lint/`

## Related Docs

- [Getting Started](getting-started.md)
- [Usage Guide](usage.md)
- Runtime discovery: `ace-nav wfi://lint/*`
