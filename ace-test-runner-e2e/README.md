<div align="center">
  <h1> ACE - Test Runner E2E </h1>

  Agent-executed end-to-end tests with reproducible sandboxes and structured reporting.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-test-runner-e2e"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-test-runner-e2e.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-test-runner-e2e demo](docs/demo/ace-test-runner-e2e-getting-started.gif)

`ace-test-runner-e2e` runs realistic workflow scenarios through coding agents so teams can validate behavior beyond unit and integration coverage while keeping execution reproducible and isolated from the working tree.

## How It Works

1. Discover E2E scenario definitions from package-local `test/e2e/` suites with metadata, tags, and command flows.
2. Execute scenarios inside reproducible sandboxes that isolate agent runs from the working tree.
3. Produce structured reports that are easy to inspect, compare across runs, and feed back into triage workflows.

## Use Cases

**Validate real developer workflows end-to-end** - use `/as-e2e-run` or run `ace-test-e2e` to confirm that instructions, tooling, and outputs behave correctly under agent execution for any package.

**Run broad regression sweeps across packages** - use `ace-test-e2e-suite` for cross-package scenario orchestration with filtering by package, tags, and prior failures.

**Keep execution deterministic and reviewable** - execute in sandboxes with structured outputs so results are reproducible and easy to compare across runs, complementing fast loops from [ace-test-runner](../ace-test-runner).

**Create and maintain E2E scenarios** - use `/as-e2e-create` to scaffold new scenarios and `/as-e2e-rewrite` or `/as-e2e-fix` to keep existing ones current as workflows evolve.

**Plan E2E coverage for new features** - use `/as-e2e-plan-changes` to map which scenarios need updates when instructions or tooling change, and `/as-e2e-review` to audit scenario quality.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
