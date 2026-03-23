# ace-git-commit

Intention-aware conventional commit generation from diffs.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md) | [Comparison Notes](COMPARISON.md)

![ace-git-commit demo](docs/demo/ace-git-commit-getting-started.gif)

`ace-git-commit` helps developers and coding agents turn repository changes into clear, scoped commit messages while staying inside the terminal workflow.

## Use Cases

**Generate high-quality commits from staged or unstaged changes** - run `ace-git-commit` to stage (by default), analyze the diff, and produce a conventional commit message.

**Guide message intent when diff context is not enough** - pass `-i "fix auth bug"` so the generated message reflects purpose, not only file deltas.

**Handle monorepo work without manual commit slicing** - commit path-scoped changes directly or rely on scope-aware splitting across packages.

**Preview and control commit behavior safely** - use `--dry-run`, `--only-staged`, `--no-split`, or `-m` depending on whether you want preview, strict staging, split control, or explicit messages.

## Works With

- **[ace-git](../ace-git)** for repository context, diff analysis, and status operations.
- **[ace-llm](../ace-llm)** for provider abstraction and model execution.
- **[ace-support-config](../ace-support-config)** for configuration cascade and project/user overrides.

## Features

- LLM-backed conventional commit generation from repository diffs.
- Intention-guided messages via `--intention` / `-i`.
- Optional direct message mode via `--message` / `-m`.
- Path-scoped commits by passing explicit files or directories.
- Scope-based split commits for multi-package change sets.
- Dry-run previews with `--dry-run`.
- Staged-only execution with `--only-staged`.
- Split control with `--no-split`.
- Configuration cascade: gem defaults -> project `.ace/` -> user `~/.ace/`.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- [Comparison Notes](COMPARISON.md)
- Command help: `ace-git-commit --help`

## Agent Skills

Package-owned canonical skills:

- `as-git-commit`

## Part of ACE

`ace-git-commit` is part of [ACE](../README.md) (Agentic Coding Environment).
