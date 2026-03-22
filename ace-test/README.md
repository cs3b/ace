---
doc-type: user
title: ACE Test Gem
purpose: Documentation landing page for ace-test
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ACE Test Gem

Testing knowledge base for ACE -- guides, patterns, and workflows for fast, reliable tests.

## Why

`ace-test` is the documentation package for testing in ACE. It provides one place for test strategy, review patterns, workflow workflows, and agent instructions.  
Use `ace-test-runner` when you need to run tests.

## Works With

- `ace-test-runner`: test execution CLI and runtime behavior
- `ace-bundle`: load guides and workflows via protocol URIs
- `ace-nav`: discover and resolve protocol resources

## Agent Skills

- `as-test-plan`: build task-level coverage plans
- `as-test-create-cases`: generate coverage-based test tasks
- `as-test-fix`: execute test failure repair loop
- `as-test-improve-coverage`: analyze and plan missing coverage
- `as-test-verify-suite`: validate suite health and structure
- `as-test-optimize`: identify and fix slow tests
- `as-test-performance-audit`: run focused test performance analysis
- `as-test-review`: apply quality review presets

## Features

- Protocol-first documentation access (`guide://`, `wfi://`, `agent://`)
- Language-agnostic testing guides (Ruby, Rust, JavaScript/Vue, Bun, and more)
- Practical workflow entry points for test planning, review, optimization, and coverage
- Quick reference and getting-started guides for both humans and agents

## Documentation

- [Getting Started](docs/getting-started.md)
- [Usage Guide](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- [`ace-test` changelog](CHANGELOG.md)

## Quick Access

- `ace-bundle guide://quick-reference`
- `ace-bundle guide://testing-philosophy`
- `ace-bundle wfi://test/create-cases`
- `ace-bundle wfi://test/fix`

For the test execution CLI, go to `ace-test-runner`: https://github.com/cs3b/ace/tree/main/ace-test-runner
