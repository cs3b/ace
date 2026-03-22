---
doc-type: user
title: Ace::TestRunner Handbook Reference
purpose: Documentation for ace-test-runner/docs/handbook.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Ace::TestRunner Handbook Reference

## Skills and workflows

| Skill | What it does |
|-------|-------------|
| `as-test-plan` | Create task-level test execution plans |
| `as-test-create-cases` | Convert behaviors into test cases |
| `as-test-fix` | Execute structured test-failure repair workflows |
| `as-test-improve-coverage` | Surface and plan coverage gaps |
| `as-test-verify-suite` | Run suite health checks |
| `as-test-optimize` | Profile and improve slow tests |
| `as-test-performance-audit` | Run focused test performance analysis |
| `as-test-review` | Apply quality review templates to test deliverables |

## Workflow protocols

| Protocol | Purpose |
|----------|---------|
| `wfi://test/plan` | Plan test changes and implementation sequence |
| `wfi://test/create-cases` | Create follow-up test coverage tasks |
| `wfi://test/fix` | Remediate failing test runs |
| `wfi://test/improve-coverage` | Add tasks for missing coverage |
| `wfi://test/verify-suite` | Validate suite behavior and quality |
| `wfi://test/optimize` | Reduce slow or unstable tests |
| `wfi://test/performance-audit` | Produce a structured performance profile |
| `wfi://test/review` | Review test and execution work |
| `wfi://test/analyze-failures` | triage repeated failure patterns |

## Source paths

- Runtime and CLI: `lib/ace/test_runner/cli/commands/test.rb`
- Option parsing: `lib/ace/test_runner/molecules/cli_argument_parser.rb`
- Suite runner: `exe/ace-test-suite`
- Defaults: `.ace-defaults/test-runner/config.yml`
- Docs: `docs/getting-started.md`, `docs/usage.md`, `docs/handbook.md`
