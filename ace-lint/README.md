# ace-lint

Ruby-only linting for markdown, YAML, and Ruby -- no Node.js or Python required.

![ace-lint demo](docs/demo/ace-lint-getting-started.gif)

## Why ace-lint

`ace-lint` gives you one Ruby-native command to validate markdown, YAML, Ruby, and frontmatter. It favors fast defaults, clear output, and configuration cascade support so most projects work with zero setup.

## Works With

- **[ace-support-config](../ace-support-config)** - user/project/default configuration cascade
- **[ace-support-cli](../ace-support-cli)** - consistent CLI option behaviors
- **[ace-docs](../ace-docs)** - metadata and doc workflows that pair with lint validation

## Agent Skills

- **`as-lint-run`** - run lint checks with optional fix/report modes
- **`as-lint-process-report`** - analyze lint reports and route follow-up tasks
- **`as-lint-fix-issue-from`** - apply focused fixes from lint findings

See [Handbook Reference](docs/handbook.md) for the complete catalog.

## Features

- **Single Ruby stack** - markdown, YAML, Ruby, and frontmatter in one gem
- **Auto-fix support** - format markdown and Ruby with `--fix`
- **Validator control** - choose validator sets such as `standardrb,rubocop`
- **Doctor diagnostics** - inspect configuration and validator health quickly
- **Config cascade** - project/user/defaults with predictable override order
- **Colorized reporting** - clear pass/fail output suitable for local and CI use

## Documentation

- [Getting Started](docs/getting-started.md) - tutorial workflow
- [Usage Guide](docs/usage.md) - full CLI reference
- [Handbook Reference](docs/handbook.md) - skills and workflows
- Runtime help: `ace-lint --help`

## Part of ACE

`ace-lint` is part of [ACE](../README.md) (Agentic Coding Environment), a CLI-first toolkit for agent-assisted development.
