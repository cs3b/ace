<div align="center">
  <h1> ACE - Test Runner </h1>

  AI-friendly test runner with smart grouping, failure analysis, and persistent reports.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-test-runner"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-test-runner.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-test-runner demo](docs/demo/ace-test-runner-getting-started.gif)

`ace-test-runner` wraps [Minitest](https://github.com/minitest/minitest) with smart grouping, cross-package resolution, and persistent reports so both developers and coding agents can run focused checks quickly, diagnose failures with context, and retain searchable execution history. It handles the execution side of testing; use [ace-test](../ace-test) for planning, review, and suite improvement workflows.

## How It Works

1. Resolve the target package and test scope from a package name, group (`atoms`, `molecules`, `organisms`, `unit`, `integration`, `system`, `all`, `quick`), or direct `file:line` selector.
2. Execute the matching tests with failure-oriented output and optional profiling of the slowest cases.
3. Persist structured run reports for historical debugging and searchable triage across runs.

## Use Cases

**Run package tests from anywhere in the monorepo** - execute [`ace-test [package]`](docs/usage.md) by name without changing directories, keeping outputs consistent across local and CI environments.

**Target exactly the scope you need** - run by test groups (`ace-test atoms`, `ace-test molecules`) or direct file/line selectors (`ace-test test/file_test.rb:42`) to focus on the code you are changing.

**Speed up triage on broken builds** - use failure-oriented output and persisted reports to locate regressions and continue diagnosis without rerunning broad suites.

**Validate the full monorepo before shipping** - run `ace-test-suite` for cross-package execution orchestration that covers every package in one sweep.

**Profile slow tests** - run `ace-test molecules --profile 10` to identify the slowest tests and prioritize optimization with [ace-test](../ace-test) performance audit workflows.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
