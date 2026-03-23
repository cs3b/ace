# ace-sim

Run multi-provider simulation chains for ideas and task specs before implementation.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-sim getting started](docs/demo/ace-sim-run.gif)

`ace-sim` executes preset-driven simulation steps (`draft`, `plan`, `work`) across one or more providers, then
optionally synthesizes suggestions and revised source artifacts for follow-up work.

## Use Cases

**Validate ideas before committing to implementation** - run `validate-idea` to compare model reasoning and stress-test
assumptions from a single source file.

**Review task specs before coding starts** - run `validate-task` to inspect plan/work outputs across providers and
iteration counts.

**Compare provider behavior under the same workflow** - use repeated `--provider` and `--repeat` options to evaluate
consistency and convergence in simulation outputs.

## Works With

- **[ace-bundle](../ace-bundle)** for source collection and context assembly before simulation chains run.
- **[ace-llm](../ace-llm)** for provider execution across chain steps and final synthesis flows.
- **[ace-task](../ace-task)** and **[ace-assign](../ace-assign)** for task-centered simulation and validation loops.
- **[ace-review](../ace-review)** for post-simulation recommendation review workflows.

## Features

- Preset-driven simulation (`validate-idea`, `validate-task`) with configurable step sequences.
- Multi-provider and repeat-aware execution via `--provider` and `--repeat`.
- Optional step override support with `--steps` for focused runs.
- Optional synthesis + writeback controls (`--synthesis-workflow`, `--synthesis-provider`, `--writeback`).
- Deterministic run artifacts under `.ace-local/sim/simulations/<run-id>/` for traceable review.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-sim --help`

## Agent Skills

- `as-sim-run`

## Part of ACE

`ace-sim` is part of [ACE](../README.md) (Agentic Coding Environment).
