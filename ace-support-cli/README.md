<div align="center">
  <h1> ACE - Support CLI </h1>

  Shared command primitives for consistent ACE CLI behavior.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-support-cli"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-support-cli.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-cli` is the foundation layer for ACE commands, providing metadata-driven command definitions, parser behavior, and execution orchestration. Packages like [ace-llm](../ace-llm), [ace-review](../ace-review), and [ace-search](../ace-search) build their CLI surfaces on top of these shared primitives.

## How It Works

1. Package commands extend shared `Command` base classes and define arguments/options declaratively.
2. Parsers normalize argv into structured Ruby types and route to a command registry.
3. Runners execute command objects with consistent help, error, and exit semantics.

## Use Cases

**Build a new ACE CLI tool quickly** - reuse shared conventions for command declaration, option parsing, and execution so new packages like [ace-retro](../ace-retro) or [ace-sim](../ace-sim) get consistent behavior from day one.

**Standardize command behavior across packages** - enforce predictable option parsing, help text, and exit codes for both human and agent callers.

**Keep agent invocations safe** - preserve a stable CLI contract so coding agents can call `ace-*` tools reliably in mixed human/agent workflows.

## Testing

This package is **fast-only** in the ACE testing model.

- Deterministic test coverage lives under `test/fast/`.
- This migration does not introduce `test/feat/` or `test/e2e/` for this package.

Verification commands:

- `ace-test ace-support-cli`
- `ace-test ace-support-cli all`

---

Part of [ACE](https://github.com/cs3b/ace)
