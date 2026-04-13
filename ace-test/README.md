<div align="center">
  <h1> ACE - Test </h1>

  Testing knowledge base for ACE — guides, patterns, and workflows for fast, reliable tests.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-test"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-test.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

`ace-test` is the handbook and workflow package for testing in ACE. It centralizes strategy guides, workflow instructions, and skill entry points for agents and developers. Use [ace-test-runner](../ace-test-runner) when you need to execute tests; use `ace-test` when you need to plan, review, or improve them.

## How It Works

1. Load test planning and strategy content through protocol URLs (`guide://`, `wfi://`, `agent://`) via [ace-bundle](../ace-bundle).
2. Invoke agent skills like `/as-test-plan` or `/as-test-fix` to drive structured test workflows with full context.
3. Apply review, coverage, and optimization guidance to improve suite quality iteratively.

## Use Cases

**Plan test coverage before implementation starts** - use `/as-test-plan` and `/as-test-create-cases` to map expected behavior, ownership, and verification checkpoints before writing code.

**Repair failing tests with a repeatable workflow** - use `/as-test-fix` to follow structured failure triage and fix loops that isolate regressions quickly and restore green runs with evidence.

**Improve suite quality over time** - use `/as-test-improve-coverage` and `/as-test-performance-audit` to identify weak spots, prioritize upgrades, and keep the fast loop healthy alongside [ace-test-runner](../ace-test-runner) execution.

**Standardize review quality for test code** - use `/as-test-review` for dedicated test review workflows covering mock quality, layering fit, and maintainability.

**Verify full-suite health** - use `/as-test-verify-suite` to confirm that the complete test suite passes after changes, coordinating with [`ace-test-runner`](../ace-test-runner) for execution.

## Testing Contract

This package is **fast-only** in the ACE testing model.

- Deterministic coverage lives under `test/fast/`.
- This migration does not introduce `test/feat/` or `test/e2e/` for this package.

Verification commands:

- `ace-test ace-test`
- `ace-test ace-test all`

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
