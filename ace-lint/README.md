# ace-lint

Ruby-native linting for markdown, YAML, and Ruby with no Node.js or Python runtime required.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-lint demo](docs/demo/ace-lint-getting-started.gif)

`ace-lint` gives developers and coding agents a single Ruby-first lint command that validates docs and code,
applies safe auto-fixes, and keeps behavior predictable through config cascade defaults.

## Use Cases

**Validate markdown, YAML, and Ruby in one pass** - run one command for doc and code lint checks without
mixing Node/Python tooling into Ruby projects.

**Apply low-risk formatting fixes before review** - use `--fix` to automatically clean markdown and Ruby style
issues prior to manual review.

**Standardize lint behavior across teams and repos** - rely on user/project/default cascade settings for
consistent validator sets and output modes.

## Works With

- **[ace-support-config](../ace-support-config)** for user/project/default configuration cascade behavior.
- **[ace-support-cli](../ace-support-cli)** for consistent CLI option handling and command UX conventions.
- **[ace-docs](../ace-docs)** for documentation maintenance workflows that pair with lint validation.

## Features

- Ruby-only lint stack for markdown, YAML, Ruby, and frontmatter.
- Auto-fix support for markdown and Ruby with `--fix`.
- Configurable validator sets (for example `standardrb,rubocop`).
- Doctor diagnostics for validator and configuration troubleshooting.
- Predictable configuration cascade: CLI flags, project, user, defaults.
- Colorized pass/fail reporting for local development and CI logs.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-lint --help`

## Agent Skills

Package-owned canonical skills:

- `as-lint-run`
- `as-lint-process-report`
- `as-lint-fix-issue-from`

## Part of ACE

`ace-lint` is part of [ACE](../README.md) (Agentic Coding Environment).
