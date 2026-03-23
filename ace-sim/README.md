<div align="center">
  <h1> ACE - Sim </h1>

  Run multi-provider simulation chains for ideas and task specs before implementation.

  <img src="https://raw.githubusercontent.com/cs3b/ace/main/docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-sim"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-sim.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-sim demo](docs/demo/ace-sim-run.gif)

`ace-sim` executes preset-driven simulation steps (draft, plan, work) across one or more providers via [ace-llm](../ace-llm), then optionally synthesizes suggestions and revised source artifacts for follow-up work. Use `/as-sim-run` to launch simulations from inside a coding agent.

## How It Works

1. Select a simulation preset (`validate-idea` or `validate-task`) and provide a source file, with context assembled by [ace-bundle](../ace-bundle).
2. The simulation engine runs each step across the configured providers and iteration counts through [ace-llm](../ace-llm).
3. Results are saved as deterministic run artifacts under `.ace-local/sim/simulations/<run-id>/`, with optional synthesis and writeback to source files.

## Use Cases

**Validate ideas before committing to implementation** - run `validate-idea` to compare model reasoning across providers and stress-test assumptions from a single source file.

**Review task specs before coding starts** - run `validate-task` to inspect plan/work outputs across providers and iteration counts, keeping [ace-task](../ace-task) specs sharp before delivery begins.

**Compare provider behavior under the same workflow** - use repeated `--provider` and `--repeat` options to evaluate consistency and convergence in [ace-llm](../ace-llm) simulation outputs.

**Synthesize recommendations from simulation runs** - enable `--synthesis-workflow` and `--synthesis-provider` to produce actionable suggestions, then feed results into [ace-review](../ace-review) for follow-up review.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
