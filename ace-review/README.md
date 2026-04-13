<div align="center">
  <h1> ACE - Review </h1>

  Multi-model code review with preset-based analysis for PRs, tasks, and packages.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-review"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-review.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-review demo](docs/demo/ace-review-getting-started.gif)

`ace-review` runs focused, repeatable reviews with configurable presets and parallel model execution via [ace-llm](../ace-llm). Findings are captured as feedback items with a verify, apply, and resolve lifecycle so review outcomes stay actionable.

## How It Works

1. Select a review preset (code, security, docs, PR, or custom) and target (diff, file set, or PR number) via [`ace-review`](docs/usage.md).
2. The review engine executes the prompt across one or more models through [ace-llm](../ace-llm), loading context from [ace-bundle](../ace-bundle) and diffs from [ace-git](../ace-git).
3. Findings are synthesized into feedback items with a tracked lifecycle (draft, verified, pending, resolved, skipped) and saved as session artifacts.

## Use Cases

**Review pull requests with consistent quality gates** - use `/as-review-pr` or [`ace-review --pr`](docs/usage.md) to run preset-driven reviews over PR diffs with optional GitHub comment publication.

**Run multi-model analysis in parallel** - execute the same review prompt across multiple [ace-llm](../ace-llm) providers, then synthesize overlapping and conflicting findings.

**Manage feedback as tracked work** - use `/as-review-verify-feedback` and `/as-review-apply-feedback` to move findings through draft, verified, pending, resolved, and skipped states, or use [`ace-review-feedback`](docs/usage.md) from the CLI to list, verify, apply, and resolve feedback items directly.

**Scope reviews to packages or tasks** - use `/as-review-package` for package-level analysis or connect reviews to [ace-task](../ace-task) workflows for task-scoped quality checks.

**Audit review history through session artifacts** - keep saved review sessions under `.ace-local/` for traceability, comparison, and handoff across contributors.

## Testing

Run package deterministic checks with:

```bash
ace-test ace-review
ace-test ace-review feat
ace-test ace-review all
```

Run retained workflow scenarios with:

```bash
ace-test-e2e ace-review
```

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
